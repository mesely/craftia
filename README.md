# Usta

Yakındaki ustaları (elektrik, tesisat, tadilat, klima, beyaz eşya, temizlik…) keşfet, filtrele, fiyat listesine, yapılan işlere ve yorumlara bak, tek dokunuşla ara veya talep gönder.

## Mimari

```
Flutter uygulaması  ──HTTPS/REST──▶  server (NestJS)  ──▶  MongoDB   (ya da DATA_SOURCE=mock)
```

- **`lib/`** — Flutter istemcisi. Riverpod (state), go_router (navigasyon), Dio (ağ).
  `UI → Notifier → Repository → RemoteDataSource → ApiClient`. Widget'lar ham HTTP çağırmaz.
  Tasarım sistemi `lib/core/theme/` altında (renk, boşluk, radius, tipografi, gölge, süre).
- **`server/`** — tek parça (modular monolith) NestJS API: `providers`, `reviews`, `orders` (hizmet talepleri), `users`, `notifications`, `categories`.
  Her modülün bir repository'si var: `Mock…` (bellekte örnek veri) ve `Mongo…` (Mongoose). Hangisinin kullanılacağını yalnızca `DATA_SOURCE` belirler.
- MongoDB bilgileri yalnızca backend'de durur. Flutter uygulaması sadece `API_BASE_URL` bilir.

### API

| | |
|---|---|
| `GET /health` | durum + veri kaynağı |
| `GET /categories` | kategori ve alt türler |
| `GET /providers` | `page, limit, mainType, subType, city, sortMode (nearest\|rating), distance, userLat, userLng, q` |
| `GET /providers/:id` | usta detayı |
| `POST /providers` | usta başvurusu (premium/doğrulama istemciden ayarlanamaz) |
| `GET/POST /providers/:id/reviews` | yorumlar (sayfalı) / yorum yaz |
| `POST /service-requests`, `GET /service-requests?userId=`, `PATCH /service-requests/:id/status` | hizmet talepleri (yalnızca iptal) |
| `GET /users/:id`, `GET /notifications?userId=` | kullanıcı, bildirim kayıtları |

## Harita

**Harita** sekmesi `lib/features/map/` altında. Harita API anahtarı gerektirmeyen şematik bir yüzey kullanır (koordinatlardan çizilen pinler, kullanıcı etrafında mesafe halkaları, yakınlaştır/kaydır). Yüzey bir arayüzün (`MapSurfaceBuilder`) arkasında durur.

Gerçek harita SDK'sı (Google Maps, Mapbox, MapLibre…) hazır olduğunda:
1. `MapSurfaceBuilder`'ı SDK widget'ıyla uygula (`MapSurfaceData.pins` → marker, `user` → kullanıcı noktası, tıklamada `onPinTap`).
2. `lib/features/map/map_surface.dart` içindeki `mapSurfaceBuilderProvider`'dan yeni uygulamayı döndür.

Başka hiçbir dosya değişmez. API anahtarı gerekiyorsa Flutter'a `--dart-define` ile ver; Mongo bilgileri gibi sunucu sırları asla uygulamaya girmez.

## Varlıklar

- `assets/brand/` — uygulama ikonu ve açılış logosu (pin içinde "U"). Yeniden üretmek için: `dart run flutter_launcher_icons` ve `dart run flutter_native_splash:create`.
- `assets/illustrations/` — boş durum ve hata çizimleri (SVG, marka paletinde, birkaç yüz bayt).
- Yazı tipi: Inter (`assets/fonts/`), ikonlar: Phosphor.

## Gereksinimler

Flutter 3.47+, Node.js 20+, (Android için Android SDK, iOS için Xcode). MongoDB sadece `DATA_SOURCE=mongo` iken gerekir.

## Çalıştırma

**Backend (mock modda, veritabanı gerekmez):**

```bash
cd server
cp .env.example .env
npm install
npm run start:dev      # http://localhost:3000
```

**Flutter:**

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

`API_BASE_URL` verilmezse Android emülatörde `http://10.0.2.2:3000`, diğerlerinde `http://localhost:3000` kullanılır.
Gerçek cihazda bilgisayarının yerel IP'sini ver (`http://192.168.x.x:3000`). Üretimde `https://` kullan.

## Yapılandırma

`server/.env` (örnek: `server/.env.example`):

```
NODE_ENV=development
PORT=3000
DATA_SOURCE=mock        # mock | mongo
MONGODB_URI=
DATABASE_NAME=usta
```

`.env` dosyaları git'e girmez. Kaynak kodda hiçbir bağlantı dizesi veya anahtar yoktur.

## Mock mod

`DATA_SOURCE=mock`: 8 şehirde, 5 kategoride 51 örnek usta; premium/normal, farklı puanlar, koordinatlar, fiyat listeleri, iş fotoğrafları ve yorumlar. Veriler bellektedir; sunucu yeniden başlayınca sıfırlanır.

## MongoDB'yi bağlamak

1. `server/.env` içinde `MONGODB_URI=` değerini ve gerekirse `DATABASE_NAME=` değerini doldur.
2. `DATA_SOURCE=mongo` yap.
3. Sunucuyu yeniden başlat. Flutter tarafında hiçbir değişiklik gerekmez.

Koleksiyon adları eski şemayla aynıdır (`providers`, `reviews`, `orders`, `users`, `notifications`), mevcut veriler okunabilir. `priceList` eski `{"Hizmet": "min-max"}` biçiminde olabilir; okunurken normalize edilir.

## Derleme

```bash
flutter build apk --debug            # Android
flutter build ios --simulator --debug  # iOS simülatör
```

## Test

```bash
flutter analyze
flutter test
cd server && npm run build && npm test
```
