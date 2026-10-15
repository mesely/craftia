# Usta

Yakınındaki ustaları (elektrik, su tesisatı, klima, boya, marangoz, beyaz eşya, temizlik…) bul, filtrele, fiyatlarına, yapılan işlere ve yorumlara bak; tek dokunuşla ara, mesaj gönder ya da hizmet talebi bırak.

## Mimari

```
Flutter uygulaması ──HTTPS/REST──▶ server (NestJS) ──▶ MongoDB Atlas   (ya da DATA_SOURCE=mock)
```

- **`lib/`** — Flutter istemcisi: Riverpod (state), go_router (navigasyon), Dio (ağ).
  `UI → Notifier → Repository → RemoteDataSource → ApiClient`. Widget'lar ham HTTP çağırmaz.
- **`server/`** — tek parça NestJS API (`providers`, `reviews`, `orders`, `users`, `notifications`, `categories`).
  Her modülün `Mock…` ve `Mongo…` repository'si var; hangisinin kullanılacağını yalnızca `DATA_SOURCE` belirler.
- MongoDB bilgileri **yalnızca** backend'de durur. Flutter uygulaması sadece `API_BASE_URL` bilir.

### Navigasyon

Üç sekme: **Ana Sayfa** (ara, hizmet seç, filtrele, ustaları gör), **Taleplerim**, **Profil**. Harita sekmesi yok: konum (GPS, şehir, koordinat, mesafe, "en yakın" sıralaması) altyapı olarak duruyor; usta sayfasındaki **Yol Tarifi** düğmesi telefonun harita uygulamasını açıyor. Dükkânı olmayan ustalarda adres yerine **Hizmet bölgesi** gösterilir.

### API

| | |
|---|---|
| `GET /health` | durum + veri kaynağı |
| `GET /categories` | kategori ve alt türler |
| `GET /providers` | `page, limit, mainType, subType, city, sortMode (nearest\|rating), distance, userLat, userLng, q` |
| `GET /providers/:id` | usta detayı |
| `POST /providers` | usta başvurusu (premium/doğrulama istemciden ayarlanamaz) |
| `GET/POST /providers/:id/reviews` | yorumlar / yorum yaz |
| `POST /service-requests`, `GET /service-requests?userId=`, `PATCH /service-requests/:id/status` | hizmet talepleri |
| `GET /users/:id`, `GET /notifications?userId=` | kullanıcı, bildirim |

## Tasarım sistemi

- `lib/core/theme/` — renk (mavi palet), boşluk, radius (8/12/16/24, hap şekli yok), tipografi (Inter), süre, kenarlık, gölge.
- **Arayüz Boyutu** (Profil → Normal / Büyük / Çok büyük): yazı, dokunma alanı, düğme yüksekliği ve kenar boşluğunu birlikte büyütür (`lib/core/accessibility/`). Telefonun kendi yazı boyutu ayarıyla *çarpılır*, onu devre dışı bırakmaz. Seçim cihazda saklanır.
- **İkonlar:** `lib/core/icons/usta_icons.dart` — Usta'ya özel, 24×24 ızgarada 2 px çizgili SVG yol verisi; senkron çizilir (yüklenme titremesi yok).
- **Hizmet görselleri:** `assets/services/*.webp` — her hizmet türü için (elektrikçi, su tesisatçısı, klima ve kombi, boyacı, dekorasyon, marangoz, beyaz eşya, elektronik, ev temizliği) tek sanat yönünde, mavi tonlu, Gemini ile üretilmiş düz illüstrasyonlar (~5 KB). Usta fotoğrafı yoksa kartta ve detayda bu görsel görünür. Eşleme: `lib/features/discovery/service_art.dart`.
- Boş durum / hata çizimleri: `assets/illustrations/`.

## Gereksinimler

Flutter 3.47+, Node.js 20+; Android için Android SDK, iOS için Xcode. MongoDB yalnızca `DATA_SOURCE=mongo` iken gerekir.

## Çalıştırma

**Backend**

```bash
cd server
cp .env.example .env     # sonra .env içini doldur (aşağıya bak)
npm install
npm run start:dev        # http://localhost:3000
```

`server/.env` (git'e girmez; `.env.example` yalnızca boş yer tutucular içerir):

```
NODE_ENV=development
PORT=3000
DATA_SOURCE=mongo        # mock = bellekte örnek veri, veritabanı gerekmez
MONGODB_URI=             # mongodb+srv://<kullanici>:<sifre>@<cluster>/  — yalnızca burada
DATABASE_NAME=usta_db
```

Bağlantıyı salt-okunur sınamak için: `npm run db:check` (DNS / kimlik / TLS / Atlas IP izni gibi hata türlerini ayırt eder, şifreyi yazdırmaz).

**Flutter**

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Android emülatörü bilgisayara `10.0.2.2` ile ulaşır (varsayılan zaten odur). Gerçek telefonda `API_BASE_URL`'e bilgisayarın yerel IP'sini ya da yayındaki API adresini ver.

## Testler

```bash
dart format . && flutter analyze && flutter test
cd server && npm run build && npm test
```

## Derleme

```bash
flutter build apk --debug          # Android
flutter build ios --simulator      # iOS (Xcode gerekir)
```
