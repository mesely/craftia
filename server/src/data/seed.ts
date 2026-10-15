import { parsePriceList } from '../common/price';
import { ProviderEntity } from '../providers/provider.types';
import { ReviewEntity } from '../reviews/review.types';

/**
 * Deterministic sample data for DATA_SOURCE=mock.
 * Covers every category, several cities, premium/normal providers, missing
 * photos/prices and a few malformed legacy price strings.
 */

function rng(seed: number) {
  let a = seed;
  return () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

interface CityDef {
  city: string;
  lat: number;
  lng: number;
  districts: string[];
}

const CITIES: CityDef[] = [
  { city: 'İstanbul', lat: 41.0082, lng: 28.9784, districts: ['Kadıköy', 'Beşiktaş', 'Üsküdar', 'Şişli', 'Ataşehir', 'Bakırköy'] },
  { city: 'Ankara', lat: 39.9334, lng: 32.8597, districts: ['Çankaya', 'Keçiören', 'Yenimahalle', 'Mamak'] },
  { city: 'İzmir', lat: 38.4237, lng: 27.1428, districts: ['Konak', 'Bornova', 'Karşıyaka', 'Buca'] },
  { city: 'Bursa', lat: 40.1826, lng: 29.0665, districts: ['Nilüfer', 'Osmangazi', 'Yıldırım'] },
  { city: 'Antalya', lat: 36.8969, lng: 30.7133, districts: ['Muratpaşa', 'Konyaaltı', 'Kepez'] },
  { city: 'Eskişehir', lat: 39.7667, lng: 30.5256, districts: ['Tepebaşı', 'Odunpazarı'] },
  { city: 'Konya', lat: 37.8746, lng: 32.4932, districts: ['Selçuklu', 'Meram', 'Karatay'] },
  { city: 'Trabzon', lat: 41.0027, lng: 39.7168, districts: ['Ortahisar', 'Akçaabat'] },
];

interface SubDef {
  mainType: string;
  subType: string;
  suffix: string;
  prices: [string, string][];
}

const SUBS: SubDef[] = [
  { mainType: 'TECHNICAL', subType: 'Elektrikçi', suffix: 'Elektrik', prices: [['Priz / Anahtar Değişimi', '150-300'], ['Avize Montajı', '250-500'], ['Sigorta Panosu Bakımı', '500-1000'], ['Kaçak Akım Arızası', '400-900']] },
  { mainType: 'TECHNICAL', subType: 'Su Tesisatçısı', suffix: 'Tesisat', prices: [['Musluk Değişimi', '200-400'], ['Gider Açma', '300-700'], ['Kaçak Tespiti', '600-1500'], ['Batarya Montajı', '250-500']] },
  { mainType: 'TECHNICAL', subType: 'Klima ve Kombi Servisi', suffix: 'Klima & Kombi Servisi', prices: [['Kombi Bakımı', '700-1200'], ['Klima Bakımı', '600-1000'], ['Klima Montajı', '2000-3500'], ['Petek Temizliği (daire)', '3000-6000']] },
  { mainType: 'CONSTRUCTION', subType: 'Boyacı', suffix: 'Boya & Badana', prices: [['Boya Badana (2+1)', '12000-20000'], ['Tavan Boyası', '3000-6000'], ['Dış Cephe Boyası', '15000-30000']] },
  { mainType: 'CONSTRUCTION', subType: 'Dekorasyon', suffix: 'Dekorasyon', prices: [['Asma Tavan (m²)', '450-750'], ['Duvar Kağıdı (m²)', '120-250'], ['Banyo Yenileme', '25000-50000']] },
  { mainType: 'CONSTRUCTION', subType: 'Marangoz', suffix: 'Marangoz', prices: [['Mutfak Dolabı Montajı', '3000-7000'], ['Kapı Ayarı', '300-700'], ['Ölçüye Dolap', '8000-20000']] },
  { mainType: 'TECH', subType: 'Beyaz Eşya Tamiri', suffix: 'Beyaz Eşya Servisi', prices: [['Çamaşır Makinesi Tamiri', '600-1500'], ['Bulaşık Makinesi Tamiri', '600-1500'], ['Buzdolabı Gaz Dolumu', '1000-2200']] },
  { mainType: 'TECH', subType: 'Elektronik Tamiri', suffix: 'Elektronik Servisi', prices: [['Ekran Arıza Tespiti', '300-600'], ['Anakart Tamiri', '1200-3000'], ['Duvara TV Montajı', '350-700']] },
  { mainType: 'LIFE', subType: 'Ev Temizliği', suffix: 'Temizlik', prices: [['2+1 Detaylı Temizlik', '1800-3200'], ['3+1 Detaylı Temizlik', '2500-4500'], ['Taşınma Sonrası Temizlik', '3000-6000']] },
];

const NAMES = ['Yıldız', 'Güven', 'Özkan', 'Demir', 'Atlas', 'Mavi', 'Yücel', 'Bora', 'Kaya', 'Çınar', 'Efe', 'Aksoy', 'Uzman', 'Ay', 'Kardeşler', 'Doğan'];
const STREETS = ['Atatürk Cd.', 'Cumhuriyet Mah.', 'İnönü Sk.', 'Gül Sk.', 'Fatih Cd.', 'Barış Mah.', 'Yeni Mah.', 'Lale Sk.'];
const AUTHORS = ['Ayşe K.', 'Mehmet Y.', 'Zeynep A.', 'Can D.', 'Elif T.', 'Burak S.', 'Selin Ö.', 'Murat B.', 'Deniz C.', 'Fatma H.'];
const COMMENTS: [number, string][] = [
  [5, 'Söylediği saatte geldi, işi temiz ve hızlı bitirdi. Kesinlikle tavsiye ederim.'],
  [5, 'Fiyat konuşulandan fazla çıkmadı, çok ilgili ve güler yüzlü.'],
  [5, 'Aynı gün içinde sorunu çözdü. Teşekkürler.'],
  [4.5, 'İşçilik kaliteli. Sadece biraz geç geldi ama haber verdi.'],
  [4, 'Genel olarak memnun kaldım, fiyat makul.'],
  [4, 'İş sonrası ortalığı toparlayıp gitti, işini biliyor.'],
  [3.5, 'İş güzel oldu ama randevu saati kaydı.'],
  [3, 'Fiyat beklediğimden biraz yüksekti, iş ise sorunsuz.'],
  [5, 'Aradığımda hemen döndü, ertesi sabah geldi. Memnun kaldım.'],
  [4.5, 'Detaylı açıkladı, gereksiz parça değiştirmedi.'],
];

function buildSeed() {
  const providers: ProviderEntity[] = [];
  const reviews: ReviewEntity[] = [];
  const rand = rng(20260);
  const pick = <T>(arr: T[]): T => arr[Math.floor(rand() * arr.length)];

  SUBS.forEach((sub, si) => {
    // İstanbul always gets one; the others rotate through the remaining cities.
    const cityIdx = [0, 1 + (si % 7), 1 + ((si + 3) % 7)];
    cityIdx.forEach((ci, k) => {
      const c = CITIES[ci];
      const district = c.districts[(si + k) % c.districts.length];
      const n = providers.length + 1;
      const id = `p${String(n).padStart(3, '0')}`;
      const isPremium = rand() < 0.22;
      // Roughly a third travel to the customer and publish no shop address.
      const mobile = n % 3 === 0;
      const lat = c.lat + (rand() - 0.5) * 0.12;
      const lng = c.lng + (rand() - 0.5) * 0.16;
      const businessName = `${pick(NAMES)} ${sub.suffix}`;
      const phone = `+9053${Math.floor(rand() * 9) + 1}${String(Math.floor(rand() * 9000000) + 1000000)}`;

      const rawPrices: Record<string, string> = {};
      if (n % 9 !== 0) {
        sub.prices.forEach(([name, range]) => (rawPrices[name] = range));
        if (n % 11 === 0) rawPrices['Keşif ve Fiyat Teklifi'] = 'Arayınız'; // malformed legacy value
        if (n % 13 === 0) rawPrices['Acil Çağrı'] = '750'; // single price
      }

      const seeds = Math.floor(rand() * 4);
      const portfolio = n % 8 === 0 ? [] : Array.from({ length: 3 + (n % 4) }, (_, i) => `https://picsum.photos/seed/usta${n}-${i}/800/600`);

      const reviewCount = n % 7 === 0 ? 0 : 2 + Math.floor(rand() * 7);
      const providerReviews: ReviewEntity[] = [];
      for (let r = 0; r < reviewCount; r++) {
        const [rating, comment] = pick(COMMENTS);
        const daysAgo = 5 + Math.floor(rand() * 330);
        providerReviews.push({
          id: `r${id}-${r}`,
          providerId: id,
          authorName: pick(AUTHORS),
          rating,
          comment,
          tags: [],
          createdAt: new Date(Date.UTC(2026, 9, 14) - daysAgo * 86400000).toISOString(),
        });
      }
      const avg = providerReviews.length
        ? Math.round((providerReviews.reduce((s, r) => s + r.rating, 0) / providerReviews.length) * 10) / 10
        : 0;
      reviews.push(...providerReviews);

      providers.push({
        id,
        businessName,
        phoneNumber: phone,
        mainType: sub.mainType,
        subType: sub.subType,
        city: c.city,
        district,
        address: mobile ? '' : `${pick(STREETS)} No:${1 + Math.floor(rand() * 90)}, ${district}/${c.city}`,
        lat,
        lng,
        rating: avg,
        reviewCount: providerReviews.length,
        isPremium,
        featuredUntil: null,
        isVerified: rand() < 0.45,
        about: `${6 + seeds * 3} yıllık tecrübeyle ${district} ve çevresinde ${sub.subType.toLocaleLowerCase('tr-TR')} hizmeti veriyoruz. Keşif ücretsiz, fiyatlar işe başlamadan önce netleştirilir.`,
        profileImage: n % 5 === 0 ? `https://picsum.photos/seed/usta-logo${n}/200/200` : null,
        portfolioImages: portfolio,
        priceList: parsePriceList(rawPrices),
        serviceAreas: mobile ? c.districts.slice(0, 3) : [],
      });
    });
  });
  return { providers, reviews };
}

const seed = buildSeed();
export const SEED_PROVIDERS: ProviderEntity[] = seed.providers;
export const SEED_REVIEWS: ReviewEntity[] = seed.reviews;
