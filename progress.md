# Usta Rebuild Progress

## Current State
Flutter client + NestJS modular monolith, working end to end against the **real MongoDB Atlas database** (`usta_db`, 9 042 providers) through the backend. Map tab removed, 3-tab navigation, blue design system, UI size setting (Normal / Büyük / Çok büyük), original icon family, Gemini-generated per-service illustrations. Branch: `flutter-rebuild`.

## Architecture
```
Flutter (Riverpod, go_router, Dio) --HTTPS/REST--> server/ (NestJS) --> MongoDB Atlas (DATA_SOURCE=mongo) | in-memory mock (DATA_SOURCE=mock)
```
- `lib/app` router+bootstrap · `lib/core` theme, accessibility (UiScale), icons, network, widgets, utils · `lib/features/*` · `lib/data` models/repositories/datasources.
- `server/src/{providers,reviews,orders,users,notifications,categories,config,common,data}`; Mock and Mongo repository per module, chosen by `DATA_SOURCE`.

## Completed
- [x] Flutter app + NestJS monolith, legacy Next.js/Capacitor/microservices removed (previous session).
- [x] Map tab and `lib/features/map` removed. Location stays (GPS, city, coordinates, haversine distance, nearest sort, distance filter). "Yol Tarifi" opens an external maps URL (`ContactLauncher.directionsUri`), shown only when the usta has a shop address; otherwise "Hizmet bölgesi".
- [x] Navigation: Ana Sayfa / Taleplerim / Profil. Search + categories + filters live inside Ana Sayfa (old "Ara" tab merged in).
- [x] Design system: blue palette (`AppColors`), 8/12/16/24 radius (no pills), Inter 13–28 sp, `AppBorders`, `UiScale`/`UiMetrics` (text factor × OS text scale, tap target 48/56/64, button height, gutter, avatar), persisted in SharedPreferences, loaded in `bootstrap` before first frame.
- [x] Icon family `lib/core/icons` (SVG path data, sync painter) incl. one icon per service; Phosphor removed.
- [x] Gemini-generated, one-style blue illustrations for the 9 real services in `assets/services/*.webp` (~50 KB total), mapped by `serviceArtAsset()` (keyword based, case/diacritic-insensitive, category fallback).
- [x] Provider card redesigned (identity, specialty, rating, district/distance, price signal, one action "Ustayı Gör"); detail page redesigned (primary "Ara", secondary "Mesaj Gönder" → sheet with SMS / hizmet talebi; price list, work photos, reviews, address/service area).
- [x] Filters: simple sheet (Hizmet türü, Şehir, Uzaklık as plain choices), sort sheet, active filter count + "Temizle". Location notice never blocks.
- [x] Backend taxonomy aligned with real data; `isVerified` is only `aiVerified` (premium = "Öne çıkan", never "doğrulanmış"); optional `serviceAreas`.
- [x] `npm run db:check` (read-only diagnostics, classifies DNS/AUTH/TLS/IP failures, never prints secrets).
- [x] Real-DB smoke test via API: health, categories, providers (filters, search, nearest + distance), detail, reviews.

## In Progress
- [ ] none

## Remaining
- [ ] Atlas data quality (not an app bug): some documents' `lat/lng` do not match their `city/district` (crawler search point), `subType` casing is lower-case, `openingFee`/`pricePerUnit` are identical placeholders (500/100) on all docs so they are NOT shown as prices, no portfolio photos / profile images / priceList in almost all docs → UI shows the service illustration and "Fiyat için arayın".
- [ ] 2dsphere index `location_2dsphere` exists but `location` is set on 1 document only; nearest sorting uses `lat/lng` in an aggregation (fine at 9k docs; add a GeoJSON backfill + `$geoNear` if the collection grows).
- [ ] Release (App Store) signing not configured; development signing works with team 8YVY52TTXP.

## Product Decisions
- No Map tab, ever. Location is infrastructure; directions are external.
- Distance is straight-line, worded "… uzakta".
- Premium = paid placement ("Öne çıkan"). Only "Doğrulanmış" is a trust mark.
- Do not invent prices: only show what the data has.
- No WhatsApp anywhere (none existed in this repo; verified by grep).

## Design Decisions
- Blue monochrome family; primary `#0F4C9A`, soft `#DDE9F8`, background `#F4F6FA`.
- Selection = border + fill + check mark (never colour alone). Status = icon + words.
- Specialties/metadata are plain text lines ("A · B"), not pill chips. Radius vocabulary only 8/12/16/24.
- Big text: category grid goes 3 → 2 columns, rows wrap instead of overflow (covered by tests at 320 dp × 1.5 system font × Büyük / Çok büyük).
- Service art is a white square thumbnail with hairline border (no transparency processing).

## Database State
- Atlas cluster `cs306cluster`, database `usta_db`: `providers` 9 042, `reviews` 3, `orders` 6, `notifications` 9, `users` 0, `locations` 0, `categories` 0 (taxonomy is served from code).
- Taxonomy in data: TECHNICAL (elektrikçi, su tesisatçısı, klima ve kombi servisi), CONSTRUCTION (boyacı, dekorasyon, marangoz), TECH (beyaz eşya tamiri, elektronik tamiri), LIFE (ev temizliği).
- Indexes present: `isPremium_-1_rating_-1`, `location_2dsphere`, `city_1_subType_1`, `isPremium_-1_createdAt_-1`, `city_1_mainType_1`. Query patterns (mainType/subType/city filter + premium/rating sort) are covered by these; no new indexes added. No writes/migrations were run against Atlas by the agent.
- Credentials live only in `server/.env` (gitignored, mode 600). `.env.example` has placeholders only (`DATABASE_NAME=usta_db`).

NEVER PUT CREDENTIALS OR SECRETS HERE.

## Files / Areas Changed
`lib/core/{theme,accessibility,icons,widgets}`, `lib/features/{discovery,provider,settings,orders,shell}`, `lib/data/models/{usta,filter_state}.dart`, `assets/{services,illustrations,brand}`, `server/src/{categories,providers,data}`, `server/scripts/db-check.js`, `test/**`, `README.md`.

## Validation
flutter analyze: no issues (last run after final edits)
flutter test: 50 passed (incl. UI-size + large system font overflow tests, no Map tab, Gemini art wiring is covered through card/detail renders)
Android build: `flutter build apk --debug` succeeded
iOS validation: release build installed and launched on a physical iPhone (wireless) against the Mac backend (API_BASE_URL=LAN IP); also verified on the iPhone 16 Pro simulator
backend build: `npm run build` ok
backend tests: 15 passed
real DB smoke test: ok (health `dataSource: mongo`, providers/categories/detail/reviews)

## Known Issues
- Disk was ~99 % full on the dev machine; Xcode DerivedData and `build/` were cleared (regenerable). Keep ≥3 GB free for Android/iOS builds.
- Gemini cannot be driven fully non-interactively; images were captured from the Gemini viewer (680 px) and compressed to 384 px WebP.

## Exact Next Steps
1. If more services appear in Atlas, add keyword rules in `serviceArtAsset`/`serviceIcon` and one Gemini illustration in the same style.
2. Optional: backfill GeoJSON `location` and use `$geoNear` if the dataset grows.
3. Release signing for Android/iOS.

## Last Known Good Commit
49ad700 (branch flutter-rebuild)
