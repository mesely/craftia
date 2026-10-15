import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../data/models/auth_methods.dart';
import '../../data/providers.dart';

/// Who-are-you provider: Firebase Authentication (e-mail + password, Google). It hands back a
/// Firebase ID token that the server verifies; the app never sees or stores a password.
///
/// [NoIdentity] is the default (tests, or a build without Firebase): [available] is false and the
/// app falls back to the sign-in against its own database.
abstract interface class IdentityProvider {
  bool get available;

  /// A Firebase ID token for a Google account, or null when the person closed the sheet.
  Future<String?> googleIdToken();

  /// A Firebase ID token for e-mail + password. With [create] the Firebase user is made first
  /// (if the address already has one with this password, that user is used).
  Future<String> emailIdToken(
    String email,
    String password, {
    bool create = false,
  });

  Future<void> sendPasswordReset(String email);

  /// Best effort: asks Firebase to send the "confirm your e-mail" message.
  Future<void> sendEmailVerification();

  /// Removes the Firebase user made during a sign-up the server then refused.
  Future<void> discardNewUser();

  Future<void> signOut();

  /// KVKK deletion: removes the Firebase user as well (best effort; needs a recent sign-in).
  Future<void> deleteUser();
}

class NoIdentity implements IdentityProvider {
  const NoIdentity();

  static const _off = AppFailure(
    FailureKind.invalid,
    'Bu giriş yöntemi şu anda kullanılamıyor.',
  );

  @override
  bool get available => false;

  @override
  Future<String?> googleIdToken() async => throw _off;

  @override
  Future<String> emailIdToken(
    String email,
    String password, {
    bool create = false,
  }) async => throw _off;

  @override
  Future<void> sendPasswordReset(String email) async => throw _off;

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> discardNewUser() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteUser() async {}
}

final identityProvider = Provider<IdentityProvider>(
  (ref) => const NoIdentity(),
);

/// Which methods the server has switched on (all off if it cannot be reached).
final authMethodsProvider = FutureProvider.autoDispose<AuthMethods>(
  (ref) => ref.watch(accountsRepositoryProvider).methods(),
);
