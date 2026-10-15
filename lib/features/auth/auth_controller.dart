import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../../data/models/account.dart';
import '../../data/models/provider_application.dart';
import '../../data/providers.dart';
import 'auth_store.dart';

class AuthState {
  const AuthState({this.account, this.onboardingSeen = false});

  final Account? account;
  final bool onboardingSeen;

  bool get signedIn => account != null;
  bool get isProvider => account?.isProvider ?? false;
}

/// Loaded once in `bootstrap` so the first frame already knows who is signed in.
final initialAuthProvider = Provider<AuthSnapshot>(
  (ref) => const AuthSnapshot(),
);

/// Mock sign-in while real authentication is not built: "admin" in any field passes.
bool isAdminToken(String value) =>
    AppConfig.mockAuth && value.trim().toLowerCase() == 'admin';

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final snapshot = ref.watch(initialAuthProvider);
    return AuthState(
      account: snapshot.account,
      onboardingSeen: snapshot.onboardingSeen,
    );
  }

  Future<void> completeOnboarding() async {
    if (state.onboardingSeen) return;
    state = AuthState(account: state.account, onboardingSeen: true);
    await AuthStore.saveOnboardingSeen();
  }

  Future<Account> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
    bool demo = false,
  }) async {
    final account = Account(
      id: AuthStore.newAccountId(),
      role: AccountRole.customer,
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      isDemo: demo,
    );
    return _finishRegistration(account, password);
  }

  /// Creates the usta's listing first, then the account that manages it.
  Future<Account> registerProvider({
    required String name,
    required String phone,
    required String email,
    required String password,
    required ProviderApplication application,
  }) async {
    final listing = await ref.read(ustaRepositoryProvider).apply(application);
    final account = Account(
      id: AuthStore.newAccountId(),
      role: AccountRole.provider,
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      providerId: listing.id,
      isDemo: application.demo,
    );
    return _finishRegistration(account, password);
  }

  /// A customer who decides to offer services: same person, usta role added.
  Future<Account> upgradeToProvider(ProviderApplication application) async {
    final current = state.account!;
    final listing = await ref.read(ustaRepositoryProvider).apply(application);
    final upgraded = Account(
      id: current.id,
      role: AccountRole.provider,
      name: current.name,
      phone: current.phone,
      email: current.email,
      providerId: listing.id,
      isDemo: application.demo,
    );
    await ref.read(accountsRepositoryProvider).upsert(upgraded);
    await _setSession(upgraded);
    return upgraded;
  }

  Future<Account> _finishRegistration(Account account, String password) async {
    await ref.read(accountsRepositoryProvider).upsert(account);
    await AuthStore.register(account, password);
    await _setSession(account);
    return account;
  }

  /// Throws an [AppFailure] with a Turkish message when the details do not match.
  Future<Account> signIn(String identifier, String password) async {
    if (isAdminToken(identifier) || isAdminToken(password)) {
      return _adminAccount();
    }
    final account = await AuthStore.verify(identifier, password);
    if (account == null) {
      final known = await AuthStore.isRegistered(identifier);
      throw AppFailure(
        FailureKind.invalid,
        known
            ? 'Şifre yanlış. Lütfen tekrar dene.'
            : 'Bu bilgilerle kayıtlı hesap bulamadık. Önce kayıt olabilirsin.',
      );
    }
    await ref.read(accountsRepositoryProvider).upsert(account);
    await _setSession(account);
    return account;
  }

  Future<Account> _adminAccount() async {
    final existing = await AuthStore.verify('admin', 'admin');
    final account =
        existing ??
        Account(
          id: 'demo-${AuthStore.newAccountId()}',
          role: AccountRole.customer,
          name: 'Admin',
          email: 'admin',
          isDemo: true,
        );
    if (existing == null) await AuthStore.register(account, 'admin');
    await ref.read(accountsRepositoryProvider).upsert(account);
    await _setSession(account);
    return account;
  }

  Future<void> signOut() async {
    await AuthStore.saveSession(null);
    state = AuthState(onboardingSeen: state.onboardingSeen);
  }

  /// KVKK right to erasure: server side first, then this phone.
  Future<void> deleteAccount() async {
    final account = state.account;
    if (account == null) return;
    await ref.read(accountsRepositoryProvider).deleteAccount(account.id);
    await AuthStore.forget(account);
    await signOut();
  }

  Future<void> _setSession(Account account) async {
    state = AuthState(account: account, onboardingSeen: true);
    await AuthStore.saveSession(account);
    await AuthStore.saveOnboardingSeen();
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
