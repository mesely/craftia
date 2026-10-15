import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/app_failure.dart';
import '../../core/firebase/firebase_options.dart';
import 'identity.dart';

/// Firebase Authentication behind [IdentityProvider]. Every Firebase error becomes a Turkish
/// [AppFailure]; raw codes never reach the screen.
class FirebaseIdentity implements IdentityProvider {
  FirebaseIdentity({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _googleReady = false;
  bool _createdNow = false;

  @override
  bool get available => true;

  Future<T> _run<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseAuthException catch (e) {
      throw _failure(e.code);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) rethrow;
      throw const AppFailure(
        FailureKind.invalid,
        'Google ile giriş yapılamadı. Tekrar dene.',
      );
    }
  }

  static AppFailure _failure(String code) => switch (code) {
    'invalid-email' => const AppFailure(
      FailureKind.invalid,
      'E-posta adresi geçersiz görünüyor.',
    ),
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' ||
    'invalid-login-credentials' => const AppFailure(
      FailureKind.invalid,
      'E-posta ya da şifre hatalı.',
    ),
    'email-already-in-use' => const AppFailure(
      FailureKind.invalid,
      'Bu e-posta ile zaten bir hesap var. Giriş yapmayı dene.',
    ),
    'weak-password' => const AppFailure(
      FailureKind.invalid,
      'Şifre çok zayıf. En az 6 karakter kullan.',
    ),
    'user-disabled' => const AppFailure(
      FailureKind.invalid,
      'Bu hesap kapatılmış. Destekle iletişime geç.',
    ),
    'too-many-requests' => const AppFailure(
      FailureKind.invalid,
      'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.',
    ),
    'network-request-failed' => AppFailure.network,
    'operation-not-allowed' => const AppFailure(
      FailureKind.invalid,
      'Bu giriş yöntemi şu anda kullanılamıyor.',
    ),
    _ => AppFailure.unknown,
  };

  @override
  Future<String?> googleIdToken() => _run(() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(
        clientId: UstaFirebase.iosClientId,
        serverClientId: UstaFirebase.webClientId,
      );
      _googleReady = true;
    }
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    final googleIdToken = account.authentication.idToken;
    if (googleIdToken == null) {
      throw const AppFailure(
        FailureKind.invalid,
        'Google ile giriş yapılamadı. Tekrar dene.',
      );
    }
    final credential = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: googleIdToken),
    );
    return (await credential.user!.getIdToken(true))!;
  });

  @override
  Future<String> emailIdToken(
    String email,
    String password, {
    bool create = false,
  }) => _run(() async {
    final mail = email.trim();
    _createdNow = false;
    UserCredential credential;
    if (create) {
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: mail,
          password: password,
        );
        _createdNow = true;
      } on FirebaseAuthException catch (e) {
        // An earlier sign-up may have stopped halfway: the same address and password just continue.
        if (e.code != 'email-already-in-use') rethrow;
        credential = await _auth.signInWithEmailAndPassword(
          email: mail,
          password: password,
        );
      }
    } else {
      credential = await _auth.signInWithEmailAndPassword(
        email: mail,
        password: password,
      );
    }
    return (await credential.user!.getIdToken(true))!;
  });

  @override
  Future<void> sendPasswordReset(String email) =>
      _run(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (_) {
      // Verification mail is a courtesy; sign-up already worked.
    }
  }

  @override
  Future<void> discardNewUser() async {
    if (!_createdNow) return;
    _createdNow = false;
    try {
      await _auth.currentUser?.delete();
    } catch (_) {
      await _auth.signOut();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (_googleReady) await GoogleSignIn.instance.signOut();
      await _auth.signOut();
    } catch (_) {
      // Signing out of the app must never fail because of the provider.
    }
  }

  @override
  Future<void> deleteUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (_) {
      await signOut();
    }
  }
}
