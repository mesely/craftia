enum ComplaintReason {
  fraud(
    'fraud',
    'Dolandırıcılık şüphesi',
    'Ödeme isteme, sahte bilgi, güveni kötüye kullanma',
  ),
  abusive(
    'abusive',
    'Kaba veya tehdit edici davranış',
    'Hakaret, taciz, tehdit',
  ),
  noShow(
    'no_show',
    'Gelmedi / hizmeti vermedi',
    'Anlaşılan işi yapmadı ya da randevuya gelmedi',
  ),
  priceDispute(
    'price_dispute',
    'Fiyat anlaşmazlığı',
    'Konuşulandan farklı ücret istendi',
  ),
  fakeInfo(
    'fake_info',
    'Yanlış veya sahte bilgi',
    'Profil, fotoğraf ya da yorum gerçeği yansıtmıyor',
  ),
  other('other', 'Diğer', 'Yukarıdakilerden biri değil');

  const ComplaintReason(this.apiValue, this.label, this.hint);
  final String apiValue;
  final String label;
  final String hint;
}

enum ComplaintTargetType { provider, customer, conversation, message }

/// What is being reported.
class ComplaintTarget {
  const ComplaintTarget({
    required this.type,
    required this.id,
    required this.name,
    this.conversationId,
  });

  final ComplaintTargetType type;
  final String id;
  final String name;
  final String? conversationId;
}

class ComplaintReceipt {
  const ComplaintReceipt({required this.reference});

  /// "SK-2026-AB12CD": quote it when contacting official channels.
  final String reference;

  factory ComplaintReceipt.fromJson(Map<String, dynamic> json) =>
      ComplaintReceipt(reference: (json['reference'] ?? '').toString());
}
