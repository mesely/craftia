# Giriş yöntemleri / Sign-in

Kimlik **Firebase Authentication** (proje `craftia-7608b`) ile kurulur; hesap kaydı, rol ve oturum uygulamanın kendi veritabanındadır.

| Yöntem | Durum |
|---|---|
| E-posta + şifre (kayıt, giriş, şifremi unuttum, doğrulama e-postası) | **Açık** |
| Google | **Açık** |
| Apple, SMS (telefon) | Sunucuda hazır, uygulamada **sunulmuyor** (`AUTH_METHODS` ile açılabilir) |

## Akış

1. Uygulama Firebase ile e-posta ya da Google kimliği alır ve bir **ID token** edinir.
2. `POST /auth/firebase` token'ı sunucuya verir. Sunucu imzayı (RS256, Google'ın yayımladığı sertifikalar), `aud`, `iss`, `exp`, `iat` alanlarını doğrular.
3. Bilinen kişi için oturum döner. Yeni kişi için `needsProfile` döner; uygulama adı (ve usta için ilan bilgilerini) alıp aynı istekte rol ile tekrar çağırır.
4. Sunucu kendi imzalı, süreli oturum belirtecini verir; korumalı uç noktalar onunla çalışır.
5. Sunucu reddederse uygulama az önce açılan Firebase kullanıcısını siler (yarım kayıt kalmaz).

Hesap eşleme: Firebase uid'ine, ardından **iki tarafta da doğrulanmış** e-postaya göre yapılır. Doğrulanmamış bir kayıt, başkasının adresiyle önceden hesap açıp sonra Google ile giren gerçek sahibi ele geçiremez.

## Yapılandırma

- Sunucu: `FIREBASE_PROJECT_ID=craftia-7608b`, `AUTH_METHODS` (varsayılan `google,email`), `AUTH_SECRET` (`openssl rand -hex 32`).
- Uygulama: `lib/core/firebase/firebase_options.dart` (herkese açık proje kimlikleri; sır değildir). iOS `Info.plist` içinde Google URL şeması, Android için hata ayıklama SHA-1/SHA-256 parmak izleri Firebase'e kayıtlıdır. **Yayın imzalı sürüm için Play Console'daki uygulama imzalama SHA-1'ini de Firebase'e ekleyin.**
- iOS bağımlılıkları CocoaPods ile çözülür (`enable-swift-package-manager: false`): Firebase 13 ile GoogleSignIn 9, Swift Package Manager'da birlikte çözülemiyor.

## Testler

`server/test/firebase-auth.spec.ts` (sahte anahtarla imzalı token'lar), `test/features/auth/federated_test.dart`, ve gerçek projede `FIREBASE_WEB_API_KEY=<web api anahtarı> npm run e2e:firebase`.
