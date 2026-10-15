import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usta/data/models/chat.dart';
import 'package:usta/data/providers.dart';
import 'package:usta/data/repositories/chat_repository.dart';
import 'package:usta/features/chat/chat_controller.dart';

import '../../helpers/fakes.dart';

/// An in-memory conversation behaving like the server: edits and deletes are soft.
class FakeChatRepository extends ChatRepository {
  FakeChatRepository() : super(MockRemoteDataSource());

  final List<ChatMessage> store = [
    ChatMessage(
      id: 'm0',
      conversationId: 'c1',
      senderId: 'test-customer-1',
      senderRole: SenderRole.customer,
      kind: MessageKind.request,
      text: 'Hizmet Talebi: Priz çalışmıyor.',
      createdAt: DateTime(2026, 10, 14, 10),
    ),
  ];
  int reads = 0;
  bool failSend = false;

  @override
  Future<ConversationInfo> conversation(String id, String viewerId) async =>
      const ConversationInfo(
        id: 'c1',
        requestId: 'r1',
        customerId: 'test-customer-1',
        customerName: 'Ayşe',
        providerId: 'u1',
        providerName: 'Ali Elektrik',
        subject: 'Elektrikçi',
        viewerRole: SenderRole.customer,
        providerOnApp: true,
      );

  @override
  Future<List<ChatMessage>> messages(
    String id,
    String viewerId, {
    DateTime? after,
  }) async => after == null
      ? [...store]
      : store.where((m) => m.changedAt.isAfter(after)).toList();

  @override
  Future<ChatMessage> send(
    String conversationId, {
    required String senderId,
    String text = '',
    String? attachmentId,
    String? replyToId,
  }) async {
    if (failSend) throw Exception('offline');
    final m = ChatMessage(
      id: 'm${store.length}',
      conversationId: conversationId,
      senderId: senderId,
      senderRole: SenderRole.customer,
      kind: MessageKind.text,
      text: text,
      replyToId: replyToId,
      createdAt: DateTime.now(),
    );
    store.add(m);
    return m;
  }

  @override
  Future<ChatMessage> edit(
    String messageId, {
    required String senderId,
    required String text,
  }) async {
    final i = store.indexWhere((m) => m.id == messageId);
    final old = store[i];
    return store[i] = ChatMessage(
      id: old.id,
      conversationId: old.conversationId,
      senderId: old.senderId,
      senderRole: old.senderRole,
      kind: old.kind,
      text: text,
      createdAt: old.createdAt,
      editedAt: DateTime.now(),
    );
  }

  @override
  Future<ChatMessage> delete(
    String messageId, {
    required String senderId,
  }) async {
    final i = store.indexWhere((m) => m.id == messageId);
    final old = store[i];
    return store[i] = ChatMessage(
      id: old.id,
      conversationId: old.conversationId,
      senderId: old.senderId,
      senderRole: old.senderRole,
      kind: old.kind,
      text: '',
      createdAt: old.createdAt,
      deletedAt: DateTime.now(),
    );
  }

  @override
  Future<void> markRead(String conversationId, String viewerId) async =>
      reads++;
}

void main() {
  late FakeChatRepository repo;
  late ProviderContainer container;
  late ProviderSubscription<ChatState> sub;

  Future<void> open() async {
    repo = FakeChatRepository();
    container = ProviderContainer(
      overrides: [
        ...testOverrides(account: testCustomer),
        chatRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    sub = container.listen(chatProvider('c1'), (_, _) {});
    addTearDown(sub.close);
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }

  ChatController controller() => container.read(chatProvider('c1').notifier);
  ChatState state() => container.read(chatProvider('c1'));

  test(
    'opens with the request as the first message and marks it read',
    () async {
      await open();
      expect(state().loading, isFalse);
      expect(state().messages.single.kind, MessageKind.request);
      expect(state().messages.single.requestBody, 'Priz çalışmıyor.');
      expect(repo.reads, greaterThan(0));
    },
  );

  test(
    'sending adds the message; replying keeps the link to the original',
    () async {
      await open();
      await controller().submit('Yarın uygun mu?');
      controller().startReply(state().messages.first);
      await controller().submit('Evet, 10:00 olur.');
      final last = state().messages.last;
      expect(last.text, 'Evet, 10:00 olur.');
      expect(last.replyToId, 'm0');
      expect(
        state().replyTo,
        isNull,
        reason: 'the reply strip closes after sending',
      );
    },
  );

  test('editing saves new text and marks it edited', () async {
    await open();
    await controller().submit('Fiyat nedir');
    final mine = state().messages.last;
    controller().startEdit(mine);
    await controller().submit('Fiyat nedir?');
    final edited = state().messages.last;
    expect(edited.text, 'Fiyat nedir?');
    expect(edited.isEdited, isTrue);
    expect(state().editing, isNull);
  });

  test('deleting leaves a "deleted" tombstone, not a hole', () async {
    await open();
    await controller().submit('Yanlış mesaj');
    final sent = state().messages.last;
    await controller().delete(sent);
    final after = state().messages.firstWhere((m) => m.id == sent.id);
    expect(after.isDeleted, isTrue);
    expect(after.text, isEmpty);
    expect(state().messages.length, 2);
  });

  test('a failed send throws so the composer keeps the text', () async {
    await open();
    repo.failSend = true;
    await expectLater(
      controller().submit('Merhaba'),
      throwsA(isA<Exception>()),
    );
    expect(state().sending, isFalse);
    expect(state().messages.length, 1);
  });

  test('empty text is never sent', () async {
    await open();
    await controller().submit('   ');
    expect(repo.store.length, 1);
  });
}
