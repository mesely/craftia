# Usta Progress

## Current State
Usta v2: Turkish-first local-services marketplace. Flutter client + NestJS modular monolith + MongoDB Atlas `usta_db` (9 042 real providers). Branch `flutter-rebuild`. Everything the last big brief asked for is implemented and tested; what is left is release hardening (see Remaining).

## Architecture
```
Flutter (Riverpod 3, go_router 18, Dio) --REST--> server/ (NestJS 12, Mongoose 9) --> MongoDB Atlas (DATA_SOURCE=mongo) | in-memory (DATA_SOURCE=mock)
```
- `lib/app` router/bootstrap/app (theme switch) · `lib/core` theme (AppPalette light/dark, typography, radius, spacing), accessibility (UiScale), icons, network, widgets, utils · `lib/features/{auth,chat,discovery,home,location,notifications,orders,profile,provider,reviews,safety,settings,shell}` · `lib/data` models/repositories/datasources.
- `server/src/{accounts,attachments,categories,common(store),complaints,conversations,notifications,orders,privacy,providers,reviews,users}`; `Store<T>` abstraction with `MemoryStore` / `MongoStore` via `StoreFactory`.

## Completed (this phase)
- [x] Navigation: Ana Sayfa / Taleplerim / **Ayarlar**. Fixed top bar (brand; notifications bell + profile button top-right). Arayüz Boyutu lives in Ayarlar only.
- [x] Home: header, search, location row ("İlçe, İl" from reverse geocoding), single filtering model = 9 Gemini picture tiles (`kServices`; Elektrik/Su/Klima separate; no "Tüm hizmetler"), results header with `Sırala:` + `Uzaklık`, `Temizle` summary. Search clears the service.
- [x] Location requested once automatically at first home open; "Konumumu kullan" notice only when not granted.
- [x] Detail page: Adres + Yol Tarifi above Fiyat listesi; "Yeni usta" text removed; thumbnail frame unchanged.
- [x] Onboarding (3 pages, Gemini art) + role choice: Usta arıyorum / Ustayım (3-step wizard, all fields mandatory except prices) / Giriş yap / Şimdilik göz at.
- [x] Mock auth (client-side, salted SHA-256 registry, server `app_accounts` upsert). **Typing `admin` in any field of login/registration passes** (disable with `--dart-define=MOCK_AUTH=false`). Usta registration with admin creates a provider flagged `isDemo`.
- [x] Chat: first message `Hizmet Talebi: <text>`, swipe-right reply, edit/delete own messages, photos, field-specific "Hazır mesajlar", Ara in header, WhatsApp/SMS options in contact sheet, soft delete, system messages, unread counters, status actions (kabul / iş bitti). Polling chat 3 s, requests 15 s.
- [x] Taleplerim redesigned (request title large, provider secondary, status wording "Ustaya iletildi" etc., "Ustayı ara").
- [x] Safety/legal: KVKK, Kullanıcı Sözleşmesi, Sorumluluk Reddi ("sahibinden usulü"), Güvenli iletişim rehberi, Şikayet ve resmi başvurular (e-Devlet Tüketici Hakem Heyeti, Ticaret Bakanlığı, ALO 175, 155), complaint form with reference number, Verilerimi indir (JSON via share sheet), Hesabımı sil (anonymises). **Legal texts are drafts: need a lawyer.**
- [x] Dark theme + Görünüm setting (Telefonu izle / Açık / Koyu), persisted (`theme_mode`). `AppColors` reads the active `AppPalette`; `UstaApp` applies it and marks the tree dirty on change (const widgets included). Illustrations sit on `artPlate`. Palettes are WCAG-AA tested.
- [x] Gemini assets: 9 service tiles, 3 onboarding illustrations, app icon + splash; app icon installed on iOS/Android.
- [x] Bug fixes found by tests: top bar overflow at large text, price list row overflow at large text, light `borderStrong`/`danger`/`success` contrast raised to AA.
- [x] README rewritten with screenshots (`docs/screenshots`).

## Added in v2.1 (this session)
- [x] New app icon (Gemini, "usta cebinde": pocket with wrench, flat blue/white, fills the square). Regenerated launcher icons + splash; adaptive bg `#1454A8`.
- [x] Dark theme art: `ArtImage` (inverts luminance + hue 180° + deep-blue plate) used by tiles, service art, onboarding.
- [x] Usta account has its own UI: tab 0 = `ProviderDashboardScreen` (Panel), Talepler with Yeni/Devam eden/Biten + Kabul et, Sayfam tab (`ProviderPageScreen` embedding `ProfileEditForm`, profile photo upload), `/promote`. Customers keep Ana Sayfa/Taleplerim/Ayarlar. Router has 4 branches (0 home, 1 requests, 2 page, 3 settings); customers redirected away from `/page`, `/promote`.
- [x] An usta never sees own listing in results (`excludeId`), cannot create a request for own listing (server guard), own detail page shows owner bar (no Ara/Mesaj).
- [x] Promotions: `server/src/promotions` (plans week 99 ₺ / month 249 ₺ / quarter 599 ₺, extends running promotion, `PAYMENTS_MODE=test|live`, `verifyReceipt()` is the only unimplemented piece); `Provider.featuredUntil` makes `isPremium` true while active; Mongo list sorts featured first.
- [x] Admin registration takes city/district/address/lat/lng from device location (reverse geocoding); "Konumumu kullan" button in the usta wizard; fallback to Kadıköy only if location is unavailable. Demo admin account/provider deleted from Atlas.
- [x] Atlas: Lütfi Yılmaz (`69936e7ca52d8737b15c08ec`) completed with `npm run db:seed-demo -- <id>` (subType elektrikçi, about, generated portrait + 4 work photos, 3 reviews, verified). Note: `aiVerified`, reviews and photos on that record are demo content.
- [x] Store readiness: version 2.1.0+3, Android release signing via `android/key.properties` + R8, `docs/RELEASE.md`, `docs/store/listing-tr.md`.
- [x] Tests: 107 Flutter, 28 server.

## v2.2 (this session)
- [x] REAL accounts: server `auth` module (`POST /auth/register|login|upgrade`, `GET /auth/me`), scrypt password hashes in `app_accounts`, HMAC-SHA256 session tokens (`AUTH_SECRET`, 90 days), global `AuthGuard` (public reads whitelisted; acting ids must equal the session; inbox only for the managing account), login lockout after 8 failures. Client sends `Authorization: Bearer`, signs out on 401. **Mock/admin bypass removed** (`MOCK_AUTH`, `isDemo`, `demo` gone). No SMS/e-mail verification yet (by request).
- [x] Home: compact first screen (small tiles, small title/search), results header = sort (left half) + distance (right half), no "Yakınında" label; card: distance is "30 km" (no "uzakta"), address on one shrinking line, price inline. Guest "Giriş yap" ends at right margin.
- [x] Settings: "Telefon varsayılanı", one-line captions, symmetric gear icon.
- [x] Lütfi Yılmaz seeded from the user's own photos (`server/seed-media`, gitignored): portrait from ~/Downloads/lutfi_usta.jpg + 10 work photos, reviewers Tuncay K. / Ahmet D.
- [x] Release artifacts (gitignored `release/`): usta-2.1.0.apk/.aab (debug-signed until `android/key.properties` exists), iOS installed on the iPhone.
- Tests: 111 Flutter, 37 server.

## Remaining
- [ ] SMS / e-mail verification and password reset (accounts and sessions are real now).
- [ ] Push notifications (FCM/APNs); payments for "Öne çıkan" (currently info/mailto only).
- [ ] Lawyer review of legal texts; App Store / Play signing.
- [ ] Atlas data quality: coordinates vs city mismatches, almost no photos/prices (UI never invents them).
- [ ] Atlas still holds test data with prefixes `simtest-`/`smoketest-` and demo providers: run `cd server && npm run db:cleanup-test simtest-` (and `smoketest-`) when finished testing.
- [ ] Visual check of provider-register wizard steps 2–3 on a device (logic is unit-tested; typing "admin" is awkward in the simulator because paste needs an OS permission prompt).

## Product Decisions
- No Map tab, ever. Directions are external ("Yol Tarifi").
- Premium = "Öne çıkan" paid placement, never "doğrulanmış". Verified only from `aiVerified`.
- Never invent prices; `openingFee`/`pricePerUnit` (500/100 placeholders) are never shown.
- Platform is a listing/communication service; disputes are between users (stated in-app; official channels linked).
- Messages are stored server-side and may be disclosed in disputes; users are told in chat, sign-up and KVKK text.

## Design Decisions
- Blue family, primary `#0F4C9A` (dark: `#6AA6F0`), radii 8/12/16/24 only, Inter, custom icon family, selection = border + fill + check.
- UiScale Normal/Büyük/Çok büyük × OS text scale; top bar wordmark and price rows adapt at very large text.

## Database State
Atlas `cs306cluster` / `usta_db`: providers 9 042 (+ a few demo/test), plus app collections created by the backend (`app_accounts`, conversations, messages, attachments, complaints, orders…). Credentials only in gitignored `server/.env`. Scripts: `npm run db:check`, `npm run db:cleanup-test <prefix>`.

NEVER PUT CREDENTIALS OR SECRETS HERE.

## Validation (last run)
- flutter analyze: no issues
- flutter test: 111 passed
- server: `npm test` 37 passed, `npm run build` ok
- Simulator (iPhone 16 Pro) verified: home, detail, contact sheet, chat, requests, notifications, settings, official page, welcome, dark theme live switch.

## Known Issues
- Keep ≥3 GB free disk for iOS/Android builds (regenerable caches: Xcode DerivedData, `build/`, ~/.gradle/caches).
- Gemini images were captured from its viewer and processed with PIL (neutral-noise cleanup, WebP).

## Exact Next Steps
1. Clean Atlas test data (command above). 2. Real auth + JWT guard on the API. 3. Push notifications. 4. Release signing and store listing.

## Last Known Good Commit
see `git log` (branch `flutter-rebuild`).
