# Giriş yöntemleri / Sign-in methods

| Yöntem | Durum | Nasıl çalışır |
|---|---|---|
| E-posta / telefon + şifre | **Açık** | Sunucuda scrypt + tuz ile saklanır; imzalı, süreli oturum belirteci |
| Google | Hazır, **pasif** | Firebase Authentication ID token'ı sunucuda doğrulanır |
| Apple | Hazır, **pasif** | Aynı yol (`apple.com` sağlayıcısı) |
| SMS (telefon numarası) | Hazır, **pasif** | Aynı yol (`phone` sağlayıcısı) |

Pasif yöntemlerin düğmeleri giriş ekranında görünür ama kapalıdır ("yakında açılacak"). Sunucu `GET /auth/methods` ile hangilerinin açık olduğunu söyler; uygulama bunu okuyup düğmeleri kendiliğinden açar.

## Açmak için üç adım

1. **Firebase projesi**: Authentication'da Google, Apple ve Telefon sağlayıcılarını etkinleştirin. iOS için `GoogleService-Info.plist`, Android için `google-services.json` dosyalarını indirin (`ios/Runner/` ve `android/app/` içine; gitignore'dadır, commit etmeyin).
2. **Sunucu**: ortam değişkenlerini girin ve yeniden başlatın.
   ```
   FIREBASE_PROJECT_ID=<proje kimliği>
   AUTH_METHODS=google,apple,phone     # istediğiniz alt küme; boşsa üçü de
   AUTH_SECRET=<openssl rand -hex 32>
   ```
3. **İstemci**: `firebase_core` ve `firebase_auth` (+ `google_sign_in`, `sign_in_with_apple`) paketlerini ekleyin ve `lib/features/auth/federated_sign_in.dart` içindeki `FederatedSignIn` arayüzünü gerçekleyin (her yöntem için Firebase ID token'ı döndürmesi yeter). `federatedSignInProvider`'ı `bootstrap.dart` içinde bu gerçeklemeyle geçersiz kılın. Apple için ayrıca Xcode'da "Sign in with Apple" yeteneğini ekleyin.

## Sunucu akışı (`POST /auth/firebase`)

1. ID token Google'ın yayımladığı sertifikalarla (RS256) doğrulanır; `aud`, `iss`, `exp`, `iat` denetlenir.
2. Hesap sırasıyla Firebase uid'ine, **doğrulanmış** e-postaya, doğrulanmış telefona göre bulunur (doğrulanmamış e-posta ile hesap birleştirilmez).
3. Bulunamazsa `needsProfile` döner; kişi adını onaylayıp rol seçer, hesap oluşturulur. Usta rolü için `provider` gövdesi gönderilir.
4. Yanıt, şifreyle girişle aynı oturum belirtecidir.

Testler: `server/test/firebase-auth.spec.ts` (sahte anahtarla imzalanmış token'lar), `test/features/auth/federated_test.dart`.
