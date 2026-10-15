import 'package:equatable/equatable.dart';

enum RequestStatus {
  pending,
  accepted,
  completed,
  cancelled;

  static RequestStatus parse(String? raw) => switch (raw) {
    'ACCEPTED' => accepted,
    'COMPLETED' => completed,
    'CANCELLED' => cancelled,
    _ => pending,
  };

  String get apiValue => name.toUpperCase();

  /// Plain words for the person looking at it. [asProvider]: the usta's point of view.
  String label({bool asProvider = false}) => switch (this) {
    pending => asProvider ? 'Yeni talep' : 'Ustaya iletildi',
    accepted => asProvider ? 'Kabul ettin' : 'Usta kabul etti',
    completed => 'Tamamlandı',
    cancelled => 'İptal edildi',
  };

  /// One calm sentence that says what happens next.
  String hint({bool asProvider = false}) => switch (this) {
    pending =>
      asProvider
          ? 'Müşteriye yanıt vererek talebi kabul edebilirsin.'
          : 'Talebin ustaya ulaştı. Yanıt verince burada göreceksin.',
    accepted =>
      asProvider
          ? 'İşi tamamlayınca “Tamamlandı” olarak işaretle.'
          : 'Usta işi üstlendi. Ayrıntıları mesajlaşarak netleştirebilirsin.',
    completed => 'Bu iş bitti. Ustayı yorumlayarak diğerlerine yardım et.',
    cancelled => 'Bu talep kapatıldı.',
  };
}

class ServiceRequest extends Equatable {
  const ServiceRequest({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.mainType,
    required this.subType,
    required this.city,
    required this.description,
    required this.status,
    required this.createdAt,
    this.conversationId,
    this.customerName = '',
    this.providerPhone = '',
    this.contactPhone = '',
    this.lastMessageAt,
    this.lastMessageText = '',
    this.unread = 0,
  });

  final String id;
  final String? providerId;
  final String? providerName;
  final String mainType;
  final String subType;
  final String city;
  final String description;
  final RequestStatus status;
  final DateTime createdAt;
  final String? conversationId;
  final String customerName;
  final String providerPhone;
  final String contactPhone;
  final DateTime? lastMessageAt;
  final String lastMessageText;
  final int unread;

  /// The request's name in lists: the first sentence of what the customer wrote.
  String get title {
    final text = description.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return 'Hizmet talebi';
    final firstSentence = text.split(RegExp(r'(?<=[.!?])\s')).first;
    if (firstSentence.length <= 56) return firstSentence;
    final cut = firstSentence.substring(0, 56);
    final lastSpace = cut.lastIndexOf(' ');
    return '${lastSpace > 24 ? cut.substring(0, lastSpace) : cut}…';
  }

  factory ServiceRequest.fromJson(Map<String, dynamic> json) => ServiceRequest(
    id: (json['id'] ?? '').toString(),
    providerId: json['providerId'] as String?,
    providerName: json['providerName'] as String?,
    mainType: (json['mainType'] ?? '').toString(),
    subType: (json['subType'] ?? '').toString(),
    city: (json['city'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    status: RequestStatus.parse(json['status'] as String?),
    createdAt:
        DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal() ??
        DateTime.now(),
    conversationId: json['conversationId'] as String?,
    customerName: (json['customerName'] ?? '').toString(),
    providerPhone: (json['providerPhone'] ?? '').toString(),
    contactPhone: (json['contactPhone'] ?? '').toString(),
    lastMessageAt: DateTime.tryParse((json['lastMessageAt'] ?? '').toString())
        ?.toLocal(),
    lastMessageText: (json['lastMessageText'] ?? '').toString(),
    unread: (json['unread'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [id, status, unread, lastMessageAt];
}

extension ServiceRequestViewer on ServiceRequest {
  /// True when [providerId] belongs to the viewer: the request came *to* them as an usta.
  bool isInboxFor(String? viewerProviderId) =>
      viewerProviderId != null && providerId == viewerProviderId;

  /// The other person in the chat, from the viewer's side.
  String otherName(String? viewerProviderId) {
    final name = isInboxFor(viewerProviderId)
        ? customerName
        : (providerName ?? '');
    if (name.isNotEmpty) return name;
    return isInboxFor(viewerProviderId) ? 'Müşteri' : 'Usta';
  }
}
