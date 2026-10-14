import { toProviderEntity } from '../src/providers/provider.mapper';

// A real document from the legacy `providers` collection (crawler output).
const legacyDoc = {
  _id: '69908fc38d88c9098f7a3d6c',
  user: '69908fc38d88c9098f7a3d69',
  businessName: 'Adana Alçı Sıva Boya | Murat Çoban Dekorasyon',
  phoneNumber: '0553 937 67 63',
  city: 'Adana',
  district: 'Aladağ',
  address: 'Adana, Belediye Evleri, 01360 Çukurova/Adana, Türkiye',
  mainType: 'CONSTRUCTION',
  subType: 'boyacı',
  lat: 37.0381498,
  lng: 35.269898500000004,
  openingFee: 500,
  pricePerUnit: 100,
};

describe('legacy Mongo provider document', () => {
  const repo = { toEntity: (d: unknown) => toProviderEntity(d) as unknown as Record<string, unknown> };

  it('maps to a usable provider, with sensible defaults for missing fields', () => {
    const p = repo.toEntity(legacyDoc);
    expect(p).toMatchObject({
      id: '69908fc38d88c9098f7a3d6c',
      businessName: 'Adana Alçı Sıva Boya | Murat Çoban Dekorasyon',
      mainType: 'CONSTRUCTION',
      subType: 'boyacı',
      lat: 37.0381498,
      lng: 35.269898500000004,
      rating: 0,
      reviewCount: 0,
      isPremium: false,
      portfolioImages: [],
      priceList: [],
      profileImage: null,
    });
  });

  it('drops an unusable (0,0) position instead of pinning it in the Atlantic', () => {
    const p = repo.toEntity({ ...legacyDoc, lat: 0, lng: 0 });
    expect(p.lat).toBeNull();
    expect(p.lng).toBeNull();
  });
});
