import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usta/core/errors/app_failure.dart';
import 'package:usta/data/models/account.dart';
import 'package:usta/data/providers.dart';
import 'package:usta/data/repositories/accounts_repository.dart';
import 'package:usta/features/auth/auth_controller.dart';
import 'package:usta/features/auth/auth_store.dart';

import '../../helpers/fakes.dart';

class FakeAccountsRepository extends AccountsRepository {
  FakeAccountsRepository() : super(MockRemoteDataSource());

  final upserted = <Account>[];
  String? deleted;

  @override
  Future<void> upsert(Account account) async => upserted.add(account);

  @override
  Future<void> deleteAccount(String accountId) async => deleted = accountId;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer container(FakeAccountsRepository accounts) {
    final c = ProviderContainer(
      overrides: [
        ...testOverrides(account: null, onboardingSeen: false),
        accountsRepositoryProvider.overrideWithValue(accounts),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'registering a customer signs them in and remembers the session',
    () async {
      final accounts = FakeAccountsRepository();
      final c = container(accounts);
      final account = await c
          .read(authProvider.notifier)
          .registerCustomer(
            name: 'Ayşe Yılmaz',
            phone: '05321234567',
            email: 'ayse@example.com',
            password: 'gizli123',
          );
      expect(c.read(authProvider).signedIn, isTrue);
      expect(c.read(authProvider).account!.id, account.id);
      expect(accounts.upserted.single.role, AccountRole.customer);
      final saved = await AuthStore.load();
      expect(saved.account?.name, 'Ayşe Yılmaz');
      expect(saved.onboardingSeen, isTrue);
    },
  );

  test('signing in checks the password, by e-mail or by phone', () async {
    final accounts = FakeAccountsRepository();
    final c = container(accounts);
    final auth = c.read(authProvider.notifier);
    await auth.registerCustomer(
      name: 'Ayşe Yılmaz',
      phone: '0532 123 45 67',
      email: 'Ayse@Example.com',
      password: 'gizli123',
    );
    await auth.signOut();
    expect(c.read(authProvider).signedIn, isFalse);

    await expectLater(
      auth.signIn('ayse@example.com', 'yanlis'),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.message,
          'message',
          contains('Şifre yanlış'),
        ),
      ),
    );
    await expectLater(
      auth.signIn('baska@example.com', 'gizli123'),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.message,
          'message',
          contains('kayıtlı hesap'),
        ),
      ),
    );
    await auth.signIn('ayse@example.com', 'gizli123');
    expect(c.read(authProvider).signedIn, isTrue);
    await auth.signOut();
    await auth.signIn('05321234567', 'gizli123');
    expect(c.read(authProvider).account!.name, 'Ayşe Yılmaz');
  });

  test('passwords are stored only as salted hashes', () async {
    final c = container(FakeAccountsRepository());
    await c
        .read(authProvider.notifier)
        .registerCustomer(
          name: 'Ayşe Yılmaz',
          phone: '05321234567',
          email: 'ayse@example.com',
          password: 'gizli123',
        );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('local_accounts')!.contains('gizli123'), isFalse);
  });

  test(
    'mock stage: "admin" in either field signs in as the demo account, once',
    () async {
      final accounts = FakeAccountsRepository();
      final c = container(accounts);
      final auth = c.read(authProvider.notifier);
      final first = await auth.signIn('admin', '');
      expect(first.isDemo, isTrue);
      await auth.signOut();
      final second = await auth.signIn('whatever', 'ADMIN');
      expect(
        second.id,
        first.id,
        reason: 'the demo account is reused, not duplicated',
      );
    },
  );

  test(
    'deleting the account clears the phone and asks the server first',
    () async {
      final accounts = FakeAccountsRepository();
      final c = container(accounts);
      final auth = c.read(authProvider.notifier);
      final account = await auth.registerCustomer(
        name: 'Ayşe Yılmaz',
        phone: '05321234567',
        email: 'ayse@example.com',
        password: 'gizli123',
      );
      await auth.deleteAccount();
      expect(accounts.deleted, account.id);
      expect(c.read(authProvider).signedIn, isFalse);
      expect((await AuthStore.load()).account, isNull);
      await expectLater(
        auth.signIn('ayse@example.com', 'gizli123'),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test('onboarding is shown once', () async {
    final c = container(FakeAccountsRepository());
    expect(c.read(authProvider).onboardingSeen, isFalse);
    await c.read(authProvider.notifier).completeOnboarding();
    expect(c.read(authProvider).onboardingSeen, isTrue);
    expect((await AuthStore.load()).onboardingSeen, isTrue);
  });
}
