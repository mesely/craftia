import '../../features/discovery/category_icons.dart' show foldTurkish;

/// One kind of work people look for. These are the "easy filters" on the home page
/// and the choices when an usta registers. [mainType] / [subType] are the values stored in the
/// database (matched case-insensitively).
class ServiceOption {
  const ServiceOption({
    required this.id,
    required this.label,
    required this.mainType,
    required this.subType,
  });

  final String id;
  final String label;
  final String mainType;
  final String subType;

  /// Gemini-generated flat illustration (assets/services).
  String get art => 'assets/services/$id.webp';

  /// Hazır mesajlar and the like are written per service family.
  String get family => mainType;
}

const kServices = <ServiceOption>[
  ServiceOption(
    id: 'elektrik',
    label: 'Elektrik',
    mainType: 'TECHNICAL',
    subType: 'Elektrikçi',
  ),
  ServiceOption(
    id: 'su',
    label: 'Su Tesisatı',
    mainType: 'TECHNICAL',
    subType: 'Su Tesisatçısı',
  ),
  ServiceOption(
    id: 'klima',
    label: 'Klima & Kombi',
    mainType: 'TECHNICAL',
    subType: 'Klima ve Kombi Servisi',
  ),
  ServiceOption(
    id: 'boya',
    label: 'Boya',
    mainType: 'CONSTRUCTION',
    subType: 'Boyacı',
  ),
  ServiceOption(
    id: 'dekorasyon',
    label: 'Dekorasyon',
    mainType: 'CONSTRUCTION',
    subType: 'Dekorasyon',
  ),
  ServiceOption(
    id: 'marangoz',
    label: 'Marangoz',
    mainType: 'CONSTRUCTION',
    subType: 'Marangoz',
  ),
  ServiceOption(
    id: 'beyaz-esya',
    label: 'Beyaz Eşya',
    mainType: 'TECH',
    subType: 'Beyaz Eşya Tamiri',
  ),
  ServiceOption(
    id: 'elektronik',
    label: 'Elektronik',
    mainType: 'TECH',
    subType: 'Elektronik Tamiri',
  ),
  ServiceOption(
    id: 'temizlik',
    label: 'Temizlik',
    mainType: 'LIFE',
    subType: 'Ev Temizliği',
  ),
];

/// The service a stored `subType` belongs to, tolerant of casing and legacy spellings
/// ("klima ve kombi servisi", "Klima Servisi"…). Null when it is not one we know.
ServiceOption? serviceFor({String? mainType, String? subType}) {
  final t = foldTurkish(subType ?? '');
  if (t.isEmpty) return null;
  for (final s in kServices) {
    if (foldTurkish(s.subType) == t) return s;
  }
  const keywords = <String, String>{
    'elektrik': 'elektrik',
    'tesisat': 'su',
    'klima': 'klima',
    'kombi': 'klima',
    'petek': 'klima',
    'boya': 'boya',
    'dekorasyon': 'dekorasyon',
    'marangoz': 'marangoz',
    'beyaz esya': 'beyaz-esya',
    'camasir': 'beyaz-esya',
    'buzdolabi': 'beyaz-esya',
    'elektronik': 'elektronik',
    'televizyon': 'elektronik',
    'tv ': 'elektronik',
    'laptop': 'elektronik',
    'temizlik': 'temizlik',
  };
  for (final e in keywords.entries) {
    if (t.contains(e.key)) return kServices.firstWhere((s) => s.id == e.value);
  }
  return null;
}
