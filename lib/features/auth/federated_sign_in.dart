import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../data/models/auth_methods.dart';
import '../../data/providers.dart';

/// Asks the platform for a Firebase ID token (Google, Apple or SMS code). The real implementation
/// needs the Firebase project files (`google-services.json`, `GoogleService-Info.plist`) and the
/// `firebase_auth` plugin; until they are added this stays [NotConfiguredFederatedSignIn], and the
/// buttons stay switched off. See docs/AUTH.md for the three steps that turn it on.
abstract interface class FederatedSignIn {
  /// The Firebase ID token, or null when the person closed the sheet.
  Future<String?> idToken(SignInMethod method);
}

class NotConfiguredFederatedSignIn implements FederatedSignIn {
  const NotConfiguredFederatedSignIn();

  @override
  Future<String?> idToken(SignInMethod method) async => throw const AppFailure(
    FailureKind.invalid,
    'Bu giriş yöntemi henüz etkin değil.',
  );
}

final federatedSignInProvider = Provider<FederatedSignIn>(
  (ref) => const NotConfiguredFederatedSignIn(),
);

/// Which methods the server has switched on (all off if it cannot be reached).
final authMethodsProvider = FutureProvider.autoDispose<AuthMethods>(
  (ref) => ref.watch(accountsRepositoryProvider).methods(),
);
