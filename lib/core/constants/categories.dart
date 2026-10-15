import '../../data/models/category.dart';

/// Built-in taxonomy: lets the app render categories instantly (and offline).
/// It mirrors the services that exist in the database; the API's /categories result
/// silently replaces it when it arrives.
const kBuiltInCategories = <ProviderCategory>[
  ProviderCategory(
    id: 'TECHNICAL',
    name: 'Elektrik, Su & Klima',
    shortName: 'Tamir',
    subTypes: [
      SubType(label: 'Elektrikçi', value: 'Elektrikçi'),
      SubType(label: 'Su Tesisatçısı', value: 'Su Tesisatçısı'),
      SubType(label: 'Klima ve Kombi', value: 'Klima ve Kombi Servisi'),
    ],
  ),
  ProviderCategory(
    id: 'CONSTRUCTION',
    name: 'Boya & Dekorasyon',
    shortName: 'Tadilat',
    subTypes: [
      SubType(label: 'Boyacı', value: 'Boyacı'),
      SubType(label: 'Dekorasyon', value: 'Dekorasyon'),
      SubType(label: 'Marangoz', value: 'Marangoz'),
    ],
  ),
  ProviderCategory(
    id: 'TECH',
    name: 'Beyaz Eşya & Elektronik',
    shortName: 'Eşya',
    subTypes: [
      SubType(label: 'Beyaz Eşya', value: 'Beyaz Eşya Tamiri'),
      SubType(label: 'Elektronik', value: 'Elektronik Tamiri'),
    ],
  ),
  ProviderCategory(
    id: 'LIFE',
    name: 'Temizlik',
    shortName: 'Hizmet',
    subTypes: [SubType(label: 'Ev Temizliği', value: 'Ev Temizliği')],
  ),
];
