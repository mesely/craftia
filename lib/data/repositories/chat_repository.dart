import '../../core/errors/app_failure.dart';
import '../datasources/remote_data_source.dart';
import '../models/chat.dart';

class ChatRepository {
  ChatRepository(this._remote);

  final RemoteDataSource _remote;

  Future<ConversationInfo> conversation(String id, String viewerId) => guarded(
    () async =>
        ConversationInfo.fromJson(await _remote.getConversation(id, viewerId)),
  );

  /// Everything, or only what is new/edited/deleted after [after].
  Future<List<ChatMessage>> messages(
    String id,
    String viewerId, {
    DateTime? after,
  }) => guarded(
    () async =>
        (await _remote.getMessages(
              id,
              viewerId,
              after: after?.toUtc().toIso8601String(),
            ))
            .whereType<Map>()
            .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false),
  );

  Future<ChatMessage> send(
    String conversationId, {
    required String senderId,
    String text = '',
    String? attachmentId,
    String? replyToId,
  }) => guarded(
    () async => ChatMessage.fromJson(
      await _remote.sendMessage(conversationId, {
        'senderId': senderId,
        if (text.isNotEmpty) 'text': text,
        'attachmentId': ?attachmentId,
        'replyToId': ?replyToId,
      }),
    ),
  );

  Future<ChatMessage> edit(
    String messageId, {
    required String senderId,
    required String text,
  }) => guarded(
    () async => ChatMessage.fromJson(
      await _remote.editMessage(messageId, {
        'senderId': senderId,
        'text': text,
      }),
    ),
  );

  Future<ChatMessage> delete(String messageId, {required String senderId}) =>
      guarded(
        () async => ChatMessage.fromJson(
          await _remote.deleteMessage(messageId, senderId),
        ),
      );

  Future<void> markRead(String conversationId, String viewerId) =>
      guarded(() => _remote.markRead(conversationId, viewerId));

  /// Uploads a (already downscaled) photo and returns its attachment id.
  Future<String> uploadPhoto(
    String conversationId, {
    required String senderId,
    required String contentType,
    required String base64Data,
  }) => guarded(() async {
    final res = await _remote.uploadAttachment(conversationId, {
      'senderId': senderId,
      'contentType': contentType,
      'data': base64Data,
    });
    return (res['id'] ?? '').toString();
  });
}
