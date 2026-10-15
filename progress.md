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

## v2.3 (this session)
- [x] **Firebase-ready sign-in, passive**: server `auth/firebase.verifier.ts` verifies Firebase ID tokens (RS256 vs Google certs, aud/iss/exp), `POST /auth/firebase`, `GET /auth/methods`; `FIREBASE_PROJECT_ID` empty => all three (google/apple/phone) off (503), `AUTH_METHODS` picks a subset. Accounts gained `emailVerified/phoneVerified/signInProvider/firebaseUid` (never returned: uid). Linking only by *verified* e-mail/phone. Client: `FederatedSignIn` interface (default `NotConfiguredFederatedSignIn`), `FederatedButtons` on login screen (disabled + "yakında açılacak" until server says on), name dialog for new people. To enable: docs/AUTH.md (3 steps; needs firebase_auth plugin + google-services files).
- [x] Deploy fix: root `Dockerfile` rewritten for `server/` (multi-stage, node 20, healthcheck, non-root) - old one built deleted microservices (Koyeb failed); `vercel.json` + static `frontend/` landing page (Vercel failed because the old Next.js app was gone). Verified locally: `npm ci` + build + prune + start + /health. TokenService no longer crashes in production without AUTH_SECRET (derives key from MONGODB_URI, warns) - still set AUTH_SECRET on the host. Koyeb needs env: DATA_SOURCE=mongo, MONGODB_URI, DATABASE_NAME=usta_db, AUTH_SECRET, PORT.
- [x] Top-right profile button shows the usta's profile photo (initials for others). Screenshots re-taken with real Lütfi photos (light/dark, panel, page).
- [x] `npm run e2e` (server/scripts/e2e.js): 31 HTTP checks, passes on mock and on Atlas.
- Tests: 115 Flutter, 45 server jest, 31 e2e.

## v2.4 (this session)
- [x] **Real Firebase Auth** (project craftia-7608b, iOS+Android apps created via firebase CLI, debug SHA-1/256 registered). App: `IdentityProvider` (`features/auth/identity.dart`, `firebase_identity.dart`), e-mail+password register/login/forgot password, Google sign-in (button only shows when app has Firebase AND server `google` on), name dialog for new Google users, rollback of a freshly created Firebase user when the server refuses sign-up. Apple and SMS are NOT shown anywhere (server code kept, off unless AUTH_METHODS lists them). Server default methods `google,email`; `FIREBASE_PROJECT_ID` in server/.env (and must be set on Koyeb). Without Firebase the app falls back to its own password sign-in (tests, mock).
- [x] Linking by e-mail/phone only when the existing account is verified too (anti pre-registration takeover) + tests.
- [x] `npm run e2e:firebase` (real Firebase user -> live API, 9 checks) passes. `npm run e2e` 31 checks passes. 120 Flutter tests, 46 jest.
- [x] iOS pods: `enable-swift-package-manager: false` in pubspec (SPM cannot resolve Firebase 13 + GoogleSignIn 9). Android builds fine. Version 2.2.0+4. Release files: release/usta-2.2.0.apk/.aab (debug-signed).
- [ ] iPhone install pending: device was "unavailable" (locked / not connected). `flutter build ios --release --dart-define=API_BASE_URL=http://<mac-ip>:3000` then `xcrun devicectl device install app --device 00008101-001115563E3A001E build/ios/iphoneos/Runner.app`.
- [ ] Koyeb runs `DATA_SOURCE=mock` (see its /health): to serve the real data set DATA_SOURCE=mongo, MONGODB_URI, DATABASE_NAME=usta_db, AUTH_SECRET, FIREBASE_PROJECT_ID there (Koyeb login was not available to me).
- [ ] Google sign-in on a real device not exercised (needs a phone / Google account); Play-signing SHA-1 must be added for store builds.
- Disk is ~99% full: free caches (Xcode DerivedData, ~/.gradle/caches) before builds; the test simulator iPhone 16 Pro was erased this session.

## Going live (production checklist, for the next stage)
Where things stand: the apps built on 2026-10-15 (iOS on two iPhones, `release/usta-2.2.0.apk/.aab`) talk to the **developer Mac** at `http://192.168.1.121:3000`, so they only work while that Mac runs `server/` (`node dist/main.js`, `.env` with DATA_SOURCE=mongo) on the same Wi-Fi. Nothing is rebuilt for production yet, by decision.

1. **Backend on Koyeb** (service already auto-deploys from `main` via the root `Dockerfile`; URL `https://dangerous-dulcia-mesely-636f9730.koyeb.app`, currently running `DATA_SOURCE=mock`). In the Koyeb service settings add: `DATA_SOURCE=mongo`, `MONGODB_URI` (from `server/.env`, never commit), `DATABASE_NAME=usta_db`, `AUTH_SECRET` (`openssl rand -hex 32`), `FIREBASE_PROJECT_ID=craftia-7608b`, optional `AUTH_METHODS` (default `google,email`), `PORT=7860` if Koyeb does not set it. Redeploy, then check `/health` says `mongo` and `/auth/methods` shows `firebase:true`.
2. **MongoDB Atlas**: Network Access must allow Koyeb's outbound IPs (or 0.0.0.0/0 with a strong DB password).
3. **Verify the live API** with the repo's own checks: `API=https://<koyeb-url> npm run e2e` and `API=https://<koyeb-url> FIREBASE_WEB_API_KEY=<web api key from lib/core/firebase/firebase_options.dart> npm run e2e:firebase` (both in `server/`; clean up with `npm run db:cleanup-test simtest-`).
4. **Rebuild the apps against the live URL** (HTTPS, no Mac needed): `flutter build apk --release --dart-define=API_BASE_URL=https://<koyeb-url>`, same for `appbundle`, `ios --release`; iOS install: `xcrun devicectl device install app --device <udid> build/ios/iphoneos/Runner.app` (the profile must include the phone; building with `-d <udid>` refreshes it). Free ≥3 GB disk first.
5. **Store release**: create an upload keystore (`android/key.properties`, see docs/RELEASE.md), add the **Play app-signing SHA-1/SHA-256** to Firebase (Android app `com.usta.usta`) or Google sign-in fails on store builds; iOS: App Store Connect build, privacy answers, review account. Enable Apple/SMS later only by adding them to `AUTH_METHODS` and adding the UI (server code is ready, app hides them).
6. **Open product items**: legal texts need a lawyer's review; push notifications (FCM/APNs); Firebase email templates (Turkish), custom domain for the API; the 3 missing Lütfi price-list rows (12 of 15 restored); payments/promotions stay in test mode and are not advertised.
7. **Housekeeping**: rotate `AUTH_SECRET` only deliberately (it signs sessions); disk on the dev Mac is ~99% full, clear `~/.gradle/caches` and Xcode DerivedData before builds.

## Remaining
- [ ] Firebase keys (then Google/Apple/SMS switch on), password reset.
- [ ] Push notifications (FCM/APNs). Promotions/payments are test mode only (not advertised in README).
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
- flutter test: 115 passed
- server: `npm test` 45 passed + `npm run e2e` 31 checks, `npm run build` ok
- Simulator (iPhone 16 Pro) verified: home, detail, contact sheet, chat, requests, notifications, settings, official page, welcome, dark theme live switch.

## Known Issues
- Keep ≥3 GB free disk for iOS/Android builds (regenerable caches: Xcode DerivedData, `build/`, ~/.gradle/caches).
- Gemini images were captured from its viewer and processed with PIL (neutral-noise cleanup, WebP).

## Exact Next Steps
1. Clean Atlas test data (command above). 2. Real auth + JWT guard on the API. 3. Push notifications. 4. Release signing and store listing.

## Last Known Good Commit
see `git log` (branch `flutter-rebuild`).
