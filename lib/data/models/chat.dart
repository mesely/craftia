import 'package:equatable/equatable.dart';

enum MessageKind { request, text, image, system }

/// Who wrote a message, from the point of view of the stored conversation.
enum SenderRole { customer, provider, system }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.kind,
    required this.text,
    required this.createdAt,
    this.attachmentId,
    this.replyToId,
    this.editedAt,
    this.deletedAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final SenderRole senderRole;
  final MessageKind kind;
  final String text;
  final String? attachmentId;
  final String? replyToId;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
  bool get isEdited => editedAt != null;

  /// The request message always reads "Hizmet Talebi: …"; the bubble shows the part after it.
  static const requestPrefix = 'Hizmet Talebi: ';
  String get requestBody => text.startsWith(requestPrefix)
      ? text.substring(requestPrefix.length)
      : text;

  /// Latest moment this message changed: used to ask the server only for news.
  DateTime get changedAt {
    var latest = createdAt;
    if (editedAt != null && editedAt!.isAfter(latest)) latest = editedAt!;
    if (deletedAt != null && deletedAt!.isAfter(latest)) latest = deletedAt!;
    return latest;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: (json['id'] ?? '').toString(),
    conversationId: (json['conversationId'] ?? '').toString(),
    senderId: (json['senderId'] ?? '').toString(),
    senderRole: switch (json['senderRole']) {
      'provider' => SenderRole.provider,
      'system' => SenderRole.system,
      _ => SenderRole.customer,
    },
    kind: switch (json['kind']) {
      'request' => MessageKind.request,
      'image' => MessageKind.image,
      'system' => MessageKind.system,
      _ => MessageKind.text,
    },
    text: (json['text'] ?? '').toString(),
    attachmentId: json['attachmentId'] as String?,
    replyToId: json['replyToId'] as String?,
    createdAt: _date(json['createdAt']) ?? DateTime.now(),
    editedAt: _date(json['editedAt']),
    deletedAt: _date(json['deletedAt']),
  );

  static DateTime? _date(dynamic raw) =>
      raw == null ? null : DateTime.tryParse(raw.toString())?.toLocal();

  @override
  List<Object?> get props => [id, text, editedAt, deletedAt, attachmentId];
}

/// Conversation header data, as seen by one of its two sides.
class ConversationInfo extends Equatable {
  const ConversationInfo({
    required this.id,
    required this.requestId,
    required this.customerId,
    required this.customerName,
    required this.providerId,
    required this.providerName,
    required this.subject,
    required this.viewerRole,
    required this.providerOnApp,
  });

  final String id;
  final String requestId;
  final String customerId;
  final String customerName;
  final String providerId;
  final String providerName;
  final String subject;
  final SenderRole viewerRole;

  /// False when the usta has no app account yet (answers may take long: suggest a call).
  final bool providerOnApp;

  bool get viewerIsProvider => viewerRole == SenderRole.provider;

  /// The other person in the chat.
  String get otherName => viewerIsProvider ? customerName : providerName;

  factory ConversationInfo.fromJson(Map<String, dynamic> json) =>
      ConversationInfo(
        id: (json['id'] ?? '').toString(),
        requestId: (json['requestId'] ?? '').toString(),
        customerId: (json['customerId'] ?? '').toString(),
        customerName: (json['customerName'] ?? '').toString(),
        providerId: (json['providerId'] ?? '').toString(),
        providerName: (json['providerName'] ?? '').toString(),
        subject: (json['subject'] ?? '').toString(),
        viewerRole: json['viewerRole'] == 'provider'
            ? SenderRole.provider
            : SenderRole.customer,
        providerOnApp: json['providerOnApp'] == true,
      );

  @override
  List<Object?> get props => [id, viewerRole, providerOnApp];
}
