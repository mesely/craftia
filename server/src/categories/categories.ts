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

/** Source of truth for the service taxonomy (mirrors the original Usta categories). */
export const CATEGORIES: Category[] = [
  {
    id: 'TECHNICAL',
    name: 'Elektrik, Isı & Su',
    shortName: 'Tamir',
    subTypes: [
      sub('Elektrik', 'Elektrikçi'),
      sub('Su Tesisat', 'Su Tesisatçısı'),
      sub('Çilingir'),
      sub('Kamera & Alarm'),
    ],
  },
  {
    id: 'CONSTRUCTION',
    name: 'Yapı & Dekorasyon',
    shortName: 'Tadilat',
    subTypes: [sub('Boyacı'), sub('Alçıpan', 'Alçıpancı'), sub('Parkeci'), sub('Fayansçı')],
  },
  {
    id: 'CLIMATE',
    name: 'İklimlendirme',
    shortName: 'İklim',
    subTypes: [sub('Kombi', 'Kombi Tamiri'), sub('Klima', 'Klima Servisi'), sub('Petek', 'Petek Temizliği')],
  },
  {
    id: 'TECH',
    name: 'Beyaz Eşya & Teknoloji',
    shortName: 'Eşya',
    subTypes: [sub('Beyaz Eşya'), sub('TV Tamiri'), sub('Laptop/PC')],
  },
  {
    id: 'LIFE',
    name: 'Temizlik & Bakım',
    shortName: 'Hizmet',
    subTypes: [sub('Ev Temizliği'), sub('İlaçlama'), sub('Koltuk Yıkama')],
  },
];
