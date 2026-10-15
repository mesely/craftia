import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usta/core/errors/app_failure.dart';
import 'package:usta/data/models/account.dart';
import 'package:usta/features/auth/auth_controller.dart';
import 'package:usta/features/auth/auth_store.dart';

import '../../helpers/fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer container(FakeAccountsRepository accounts) {
    final c = ProviderContainer(
      overrides: testOverrides(
        account: null,
        onboardingSeen: false,
        accountsRepo: accounts,
      ),
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<Account> register(ProviderContainer c) => c
      .read(authProvider.notifier)
      .registerCustomer(
        name: 'Ayşe Yılmaz',
        phone: '05321234567',
        email: 'ayse@example.com',
        password: 'gizli123',
      );

  test('registering signs the person in and remembers the session', () async {
    final accounts = FakeAccountsRepository();
    final c = container(accounts);
    final account = await register(c);
    expect(c.read(authProvider).signedIn, isTrue);
    expect(c.read(authProvider).token, 'token-${account.id}');
    expect(accounts.accounts.single.role, AccountRole.customer);
    final saved = await AuthStore.load();
    expect(saved.account?.name, 'Ayşe Yılmaz');
    expect(saved.token, 'token-${account.id}');
    expect(saved.onboardingSeen, isTrue);
  });

  test('the phone never stores a password', () async {
    final c = container(FakeAccountsRepository());
    await register(c);
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      expect('${prefs.get(key)}'.contains('gizli123'), isFalse, reason: key);
    }
  });

  test(
    'signing in works by e-mail or phone and explains a wrong password',
    () async {
      final c = container(FakeAccountsRepository());
      final auth = c.read(authProvider.notifier);
      await register(c);
      await auth.signOut();
      expect(c.read(authProvider).signedIn, isFalse);
      expect((await AuthStore.load()).token, isNull);

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
        auth.signIn('yok@example.com', 'x'),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.message,
            'message',
            contains('kayıtlı hesap'),
          ),
        ),
      );
      expect(
        (await auth.signIn('AYSE@example.com', 'gizli123')).name,
        'Ayşe Yılmaz',
      );
      await auth.signOut();
      expect(
        (await auth.signIn('0532 123 45 67', 'gizli123')).name,
        'Ayşe Yılmaz',
      );
    },
  );

  test('the same e-mail cannot register twice', () async {
    final c = container(FakeAccountsRepository());
    await register(c);
    await c.read(authProvider.notifier).signOut();
    await expectLater(register(c), throwsA(isA<AppFailure>()));
  });

  test('"admin" is just a wrong password now: there is no bypass', () async {
    final c = container(FakeAccountsRepository());
    await expectLater(
      c.read(authProvider.notifier).signIn('admin', 'admin'),
      throwsA(isA<AppFailure>()),
    );
    expect(c.read(authProvider).signedIn, isFalse);
  });

  test('a session the server refuses signs the person out', () async {
    final c = container(FakeAccountsRepository());
    await register(c);
    c.read(authProvider.notifier).sessionExpired();
    await Future<void>.delayed(Duration.zero);
    expect(c.read(authProvider).signedIn, isFalse);
  });

  test('a stored account without a server token starts signed out', () async {
    SharedPreferences.setMockInitialValues({
      'session_account': '{"id":"a","role":"customer","name":"Eski","phone":"","email":"","providerId":null}',
    });
    expect((await AuthStore.load()).account, isNull);
  });

  test('deleting the account asks the server first, then signs out', () async {
    final accounts = FakeAccountsRepository();
    final c = container(accounts);
    final account = await register(c);
    await c.read(authProvider.notifier).deleteAccount();
    expect(accounts.deleted, account.id);
    expect(c.read(authProvider).signedIn, isFalse);
    expect((await AuthStore.load()).account, isNull);
    await expectLater(
      c.read(authProvider.notifier).signIn('ayse@example.com', 'gizli123'),
      throwsA(isA<AppFailure>()),
    );
  });

  test('onboarding is shown once', () async {
    final c = container(FakeAccountsRepository());
    expect(c.read(authProvider).onboardingSeen, isFalse);
    await c.read(authProvider.notifier).completeOnboarding();
    expect(c.read(authProvider).onboardingSeen, isTrue);
    expect((await AuthStore.load()).onboardingSeen, isTrue);
  });
}
