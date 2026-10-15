import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../data/models/chat.dart';
import '../../data/providers.dart';
import '../../data/repositories/chat_repository.dart';
import '../auth/auth_controller.dart';
import '../orders/requests_controller.dart';

class ChatState {
  const ChatState({
    this.info,
    this.messages = const [],
    this.loading = true,
    this.failure,
    this.sending = false,
    this.replyTo,
    this.editing,
  });

  final ConversationInfo? info;
  final List<ChatMessage> messages;
  final bool loading;
  final AppFailure? failure;
  final bool sending;

  /// The message the next one answers (swipe right on a bubble).
  final ChatMessage? replyTo;

  /// The own message being edited.
  final ChatMessage? editing;

  ChatMessage? messageById(String? id) =>
      id == null ? null : messages.where((m) => m.id == id).firstOrNull;

  ChatState copyWith({
    ConversationInfo? info,
    List<ChatMessage>? messages,
    bool? loading,
    AppFailure? failure,
    bool clearFailure = false,
    bool? sending,
    ChatMessage? replyTo,
    bool clearReply = false,
    ChatMessage? editing,
    bool clearEditing = false,
  }) => ChatState(
    info: info ?? this.info,
    messages: messages ?? this.messages,
    loading: loading ?? this.loading,
    failure: clearFailure ? null : (failure ?? this.failure),
    sending: sending ?? this.sending,
    replyTo: clearReply ? null : (replyTo ?? this.replyTo),
    editing: clearEditing ? null : (editing ?? this.editing),
  );
}

/// One conversation: loads it, then asks the server only for what changed every few seconds.
/// (Plain polling on purpose: no sockets to keep alive, works the same on every network.)
class ChatController extends Notifier<ChatState> {
  ChatController(this.conversationId);

  final String conversationId;
  static const _pollEvery = Duration(seconds: 3);

  Timer? _timer;
  bool _polling = false;

  String get _me => ref.read(authProvider).account?.id ?? '';
  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  @override
  ChatState build() {
    ref.onDispose(() => _timer?.cancel());
    Future.microtask(_load);
    return const ChatState();
  }

  Future<void> _load() async {
    try {
      final info = await _repo.conversation(conversationId, _me);
      final messages = await _repo.messages(conversationId, _me);
      if (!ref.mounted) return;
      state = state.copyWith(
        info: info,
        messages: _sorted(messages),
        loading: false,
        clearFailure: true,
      );
      _markRead();
      _timer = Timer.periodic(_pollEvery, (_) => _poll());
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(loading: false, failure: AppFailure.from(e));
      }
    }
  }

  Future<void> retry() async {
    state = const ChatState();
    await _load();
  }

  Future<void> _poll() async {
    if (_polling || state.messages.isEmpty) return;
    _polling = true;
    try {
      final after = state.messages
          .map((m) => m.changedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final news = await _repo.messages(conversationId, _me, after: after);
      if (!ref.mounted || news.isEmpty) return;
      final merged = _merge(state.messages, news);
      state = state.copyWith(messages: merged);
      if (news.any((m) => m.senderId != _me)) _markRead();
    } catch (_) {
      // Quiet: the next tick retries.
    } finally {
      _polling = false;
    }
  }

  void _markRead() {
    _repo
        .markRead(conversationId, _me)
        .then((_) {
          if (ref.mounted) ref.read(requestsProvider.notifier).refresh();
        })
        .catchError((_) {});
  }

  static List<ChatMessage> _sorted(List<ChatMessage> list) =>
      [...list]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  static List<ChatMessage> _merge(
    List<ChatMessage> current,
    List<ChatMessage> news,
  ) {
    final byId = {for (final m in current) m.id: m};
    for (final m in news) {
      byId[m.id] = m;
    }
    return _sorted(byId.values.toList());
  }

  void startReply(ChatMessage m) =>
      state = state.copyWith(replyTo: m, clearEditing: true);
  void cancelReply() => state = state.copyWith(clearReply: true);
  void startEdit(ChatMessage m) =>
      state = state.copyWith(editing: m, clearReply: true);
  void cancelEdit() => state = state.copyWith(clearEditing: true);

  /// Sends (or, when editing, saves) [text]. Throws [AppFailure] so the composer keeps the text.
  Future<void> submit(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(sending: true);
    try {
      final editing = state.editing;
      if (editing != null) {
        final saved = await _repo.edit(
          editing.id,
          senderId: _me,
          text: trimmed,
        );
        if (ref.mounted) {
          state = state.copyWith(
            messages: _merge(state.messages, [saved]),
            clearEditing: true,
          );
        }
      } else {
        final sent = await _repo.send(
          conversationId,
          senderId: _me,
          text: trimmed,
          replyToId: state.replyTo?.id,
        );
        if (ref.mounted) {
          state = state.copyWith(
            messages: _merge(state.messages, [sent]),
            clearReply: true,
          );
        }
      }
    } finally {
      if (ref.mounted) state = state.copyWith(sending: false);
    }
  }

  /// Uploads a photo (already downscaled by the picker) and sends it as a message.
  Future<void> sendPhoto(Uint8List bytes, String contentType) async {
    state = state.copyWith(sending: true);
    try {
      final id = await _repo.uploadPhoto(
        conversationId,
        senderId: _me,
        contentType: contentType,
        base64Data: base64Encode(bytes),
      );
      final sent = await _repo.send(
        conversationId,
        senderId: _me,
        attachmentId: id,
        replyToId: state.replyTo?.id,
      );
      if (ref.mounted) {
        state = state.copyWith(
          messages: _merge(state.messages, [sent]),
          clearReply: true,
        );
      }
    } finally {
      if (ref.mounted) state = state.copyWith(sending: false);
    }
  }

  Future<void> delete(ChatMessage m) async {
    final removed = await _repo.delete(m.id, senderId: _me);
    if (ref.mounted) {
      state = state.copyWith(
        messages: _merge(state.messages, [
          ChatMessage(
            id: removed.id,
            conversationId: removed.conversationId,
            senderId: removed.senderId,
            senderRole: removed.senderRole,
            kind: removed.kind,
            text: '',
            createdAt: removed.createdAt,
            replyToId: removed.replyToId,
            editedAt: removed.editedAt,
            deletedAt: removed.deletedAt ?? DateTime.now(),
          ),
        ]),
      );
    }
  }
}

final chatProvider = NotifierProvider.autoDispose
    .family<ChatController, ChatState, String>(ChatController.new);
