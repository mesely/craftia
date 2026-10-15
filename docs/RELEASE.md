# Mağazaya çıkış kontrol listesi / Release checklist

Usta v2.1 is feature-complete and tested. These are the things that stay *outside* the code, in the order to do them.

## 1. Must do before the first store build
| # | Item | Why / how |
|---|---|---|
| 1 | **Verification + password reset** | Accounts, scrypt hashes, signed sessions and the server guard exist. Add SMS / e-mail verification and a reset flow. Set a strong `AUTH_SECRET` (required in production). |
| 2 | **HTTPS API + hosting** | Deploy `server/` (any Node host) behind HTTPS, set `DATA_SOURCE=mongo`, `MONGODB_URI`, `DATABASE_NAME`, `NODE_ENV=production`; build the app with `--dart-define=API_BASE_URL=https://api.<your-domain>`. Rotate the Atlas password that was used during development. |
| 3 | **Payments for "Öne çıkan"** | `server/src/promotions` sells plans in `PAYMENTS_MODE=test` (no charge). For `live`: sell the three plans as consumable in-app purchases (App Store Connect / Google Play Console, product ids `usta.promo.week|month|quarter`), send the receipt in `receipt`, and implement `verifyReceipt()` against the store server APIs. Both stores require in-app purchase for digital visibility sold inside the app. |
| 4 | **Legal texts** | KVKK Aydınlatma Metni, Kullanıcı Sözleşmesi and Sorumluluk Reddi in `lib/features/settings/document_screen.dart` are drafts. A lawyer must review them; also publish them on a public URL (stores require a privacy-policy link). |
| 5 | **Remove dev-only strings** | `NSLocalNetworkUsageDescription` in `ios/Runner/Info.plist` and the local-networking ATS exception are for LAN development. |
| 6 | **Signing** | Android: create an upload key, add `android/key.properties` (`keyAlias`, `keyPassword`, `storeFile`, `storePassword`; gitignored). iOS: Distribution certificate + App Store profile for team `8YVY52TTXP`, bundle id `com.usta.usta`. |

## 2. Build
```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com
flutter build ipa --release --dart-define=API_BASE_URL=https://api.example.com
```
Bump `version:` in `pubspec.yaml` (`name+build`) for every upload.

## 3. Store listing
Text, keywords and the privacy answers are drafted in `docs/store/listing-tr.md`. Screenshots: `docs/screenshots/`.
- **Apple**: App Privacy = Contact info (name, phone, e-mail), Location (coarse/precise, app functionality), User content (messages, photos), Identifiers; not used for tracking. Age rating 4+. Review notes need a test account (create a real test account).
- **Google Play**: Data safety form with the same data types; account deletion URL/instructions (in-app: Ayarlar → Hesabımı sil).
- Both stores: user-generated content needs in-app **report** (Şikayet et) and **block/delete** paths: present.

## 4. Operations
- `npm run db:check` – connectivity; `npm run db:cleanup-test <prefix>` – remove test data; `npm run db:seed-demo -- <providerId>` – fill a demo listing.
- Add uptime monitoring on `GET /health`, daily Atlas backups, and rate limiting in front of the API.
