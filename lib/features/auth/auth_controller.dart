import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/account.dart';
import '../../data/models/auth_methods.dart';
import '../../data/models/provider_application.dart';
import '../../data/models/session.dart';
import '../../data/providers.dart';
import 'auth_store.dart';

class AuthState {
  const AuthState({this.account, this.token, this.onboardingSeen = false});

  final Account? account;
  final String? token;
  final bool onboardingSeen;

  bool get signedIn => account != null;
  bool get isProvider => account?.isProvider ?? false;
}

/// Loaded once in `bootstrap` so the first frame already knows who is signed in.
final initialAuthProvider = Provider<AuthSnapshot>(
  (ref) => const AuthSnapshot(),
);

/// Accounts live in the app's own database (passwords as salted hashes on the server); the phone
/// keeps only the signed session. There is no SMS / e-mail verification yet.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final snapshot = ref.watch(initialAuthProvider);
    return AuthState(
      account: snapshot.account,
      token: snapshot.token,
      onboardingSeen: snapshot.onboardingSeen,
    );
  }

  Future<void> completeOnboarding() async {
    if (state.onboardingSeen) return;
    state = AuthState(
      account: state.account,
      token: state.token,
      onboardingSeen: true,
    );
    await AuthStore.saveOnboardingSeen();
  }

  Future<Account> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async => _start(
    await ref
        .read(accountsRepositoryProvider)
        .registerCustomer(
          name: name,
          phone: phone,
          email: email,
          password: password,
        ),
  );

  /// Creates the usta's listing and the account that manages it.
  Future<Account> registerProvider({
    required String name,
    required String phone,
    required String email,
    required String password,
    required ProviderApplication application,
  }) async => _start(
    await ref
        .read(accountsRepositoryProvider)
        .registerProvider(
          name: name,
          phone: phone,
          email: email,
          password: password,
          application: application,
        ),
  );

  /// A customer who decides to offer services: same person, usta role added.
  Future<Account> upgradeToProvider(ProviderApplication application) async =>
      _start(await ref.read(accountsRepositoryProvider).upgrade(application));

  /// Throws an [AppFailure] with a Turkish message when the details do not match.
  Future<Account> signIn(String identifier, String password) async => _start(
    await ref.read(accountsRepositoryProvider).login(identifier, password),
  );

  /// Google / Apple / SMS. Returns the signed-in account, or null when the person has to say who
  /// they are first (see [completeFederated]) or closed the sheet.
  Future<FederatedOutcome?> signInWith(
    SignInMethod method,
    String? idToken,
  ) async {
    if (idToken == null) return null;
    final outcome = await ref
        .read(accountsRepositoryProvider)
        .firebaseLogin(idToken);
    if (!outcome.needsProfile) await _start(outcome.session as Session);
    return outcome;
  }

  /// The second step for someone new: they chose a role and confirmed their name.
  Future<Account> completeFederated(
    String idToken, {
    required String name,
    String? phone,
  }) async => _start(
    (await ref
                .read(accountsRepositoryProvider)
                .firebaseLogin(
                  idToken,
                  role: 'customer',
                  name: name,
                  phone: phone,
                ))
            .session
        as Session,
  );

  Future<void> signOut() async {
    await AuthStore.saveSession(null, null);
    state = AuthState(onboardingSeen: state.onboardingSeen);
  }

  /// KVKK right to erasure: server side first, then this phone.
  Future<void> deleteAccount() async {
    final account = state.account;
    if (account == null) return;
    await ref.read(accountsRepositoryProvider).deleteAccount(account.id);
    await signOut();
  }

  /// The server rejected the session (expired or revoked): ask the person to sign in again.
  void sessionExpired() {
    if (state.signedIn) signOut();
  }

  Future<Account> _start(Session session) async {
    state = AuthState(
      account: session.account,
      token: session.token,
      onboardingSeen: true,
    );
    await AuthStore.saveSession(session.account, session.token);
    await AuthStore.saveOnboardingSeen();
    return session.account;
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
