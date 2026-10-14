import '../../data/models/category.dart';

/// Built-in taxonomy: lets the app render categories instantly (and offline).
/// The API's /categories result silently replaces it when it arrives.
const kBuiltInCategories = <ProviderCategory>[
  ProviderCategory(
    id: 'TECHNICAL',
    name: 'Elektrik, Isı & Su',
    shortName: 'Tamir',
    subTypes: [
      SubType(label: 'Elektrik', value: 'Elektrikçi'),
      SubType(label: 'Su Tesisat', value: 'Su Tesisatçısı'),
      SubType(label: 'Çilingir', value: 'Çilingir'),
      SubType(label: 'Kamera & Alarm', value: 'Kamera & Alarm'),
    ],
  ),
  ProviderCategory(
    id: 'CONSTRUCTION',
    name: 'Yapı & Dekorasyon',
    shortName: 'Tadilat',
    subTypes: [
      SubType(label: 'Boyacı', value: 'Boyacı'),
      SubType(label: 'Alçıpan', value: 'Alçıpancı'),
      SubType(label: 'Parkeci', value: 'Parkeci'),
      SubType(label: 'Fayansçı', value: 'Fayansçı'),
    ],
  ),
  ProviderCategory(
    id: 'CLIMATE',
    name: 'İklimlendirme',
    shortName: 'İklim',
    subTypes: [
      SubType(label: 'Kombi', value: 'Kombi Tamiri'),
      SubType(label: 'Klima', value: 'Klima Servisi'),
      SubType(label: 'Petek', value: 'Petek Temizliği'),
    ],
  ),
  ProviderCategory(
    id: 'TECH',
    name: 'Beyaz Eşya & Teknoloji',
    shortName: 'Eşya',
    subTypes: [
      SubType(label: 'Beyaz Eşya', value: 'Beyaz Eşya'),
      SubType(label: 'TV Tamiri', value: 'TV Tamiri'),
      SubType(label: 'Laptop/PC', value: 'Laptop/PC'),
    ],
  ),
  ProviderCategory(
    id: 'LIFE',
    name: 'Temizlik & Bakım',
    shortName: 'Hizmet',
    subTypes: [
      SubType(label: 'Ev Temizliği', value: 'Ev Temizliği'),
      SubType(label: 'İlaçlama', value: 'İlaçlama'),
      SubType(label: 'Koltuk Yıkama', value: 'Koltuk Yıkama'),
    ],
  ),
];
