export interface SubType {
  label: string;
  value: string;
}

export interface Category {
  id: string;
  name: string;
  shortName: string;
  subTypes: SubType[];
}

const sub = (label: string, value = label): SubType => ({ label, value });

/**
 * Source of truth for the service taxonomy. It mirrors what the `providers` collection actually
 * contains (`mainType` + `subType`); matching against the database is case-insensitive.
 */
export const CATEGORIES: Category[] = [
  {
    id: 'TECHNICAL',
    name: 'Elektrik, Su & Klima',
    shortName: 'Tamir',
    subTypes: [
      sub('Elektrikçi'),
      sub('Su Tesisatçısı'),
      sub('Klima ve Kombi', 'Klima ve Kombi Servisi'),
    ],
  },
  {
    id: 'CONSTRUCTION',
    name: 'Boya & Dekorasyon',
    shortName: 'Tadilat',
    subTypes: [sub('Boyacı'), sub('Dekorasyon'), sub('Marangoz')],
  },
  {
    id: 'TECH',
    name: 'Beyaz Eşya & Elektronik',
    shortName: 'Eşya',
    subTypes: [sub('Beyaz Eşya', 'Beyaz Eşya Tamiri'), sub('Elektronik', 'Elektronik Tamiri')],
  },
  {
    id: 'LIFE',
    name: 'Temizlik',
    shortName: 'Hizmet',
    subTypes: [sub('Ev Temizliği')],
  },
];
