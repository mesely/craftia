import '../../data/models/usta.dart';

/// What makes an usta page convincing, and what is still missing. Prices are optional at
/// registration but are the single most persuasive part of a page, so they are listed too.
class CompletenessItem {
  const CompletenessItem(this.id, this.title, this.hint, this.done);

  final String id;
  final String title;
  final String hint;
  final bool done;
}

class ProfileCompleteness {
  const ProfileCompleteness(this.items);

  factory ProfileCompleteness.of(Usta usta) => ProfileCompleteness([
    CompletenessItem(
      'photo',
      'Profil fotoğrafı ekle',
      'Yüzünü gören müşteri seni daha çok arar.',
      usta.profileImage != null,
    ),
    CompletenessItem(
      'about',
      'Kendini tanıt',
      'Birkaç cümle yeter.',
      usta.about.trim().length >= 20,
    ),
    CompletenessItem(
      'prices',
      'Fiyat listeni ekle',
      'Net fiyat gören müşteri daha kolay karar verir.',
      usta.priceList.isNotEmpty,
    ),
    CompletenessItem(
      'work',
      'İş fotoğraflarını ekle',
      'En az 3 fotoğraf önerilir.',
      usta.portfolioImages.length >= 3,
    ),
    CompletenessItem(
      'place',
      usta.hasShopAddress ? 'Adresini doğrula' : 'Hizmet bölgelerini yaz',
      'Müşteriler nerede çalıştığını bilmek ister.',
      usta.hasShopAddress || usta.serviceAreas.isNotEmpty,
    ),
  ]);

  final List<CompletenessItem> items;

  int get doneCount => items.where((i) => i.done).length;
  bool get complete => doneCount == items.length;
  double get fraction => doneCount / items.length;
  Iterable<CompletenessItem> get missing => items.where((i) => !i.done);
}
