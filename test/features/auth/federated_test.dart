import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usta/app/app.dart';
import 'package:usta/core/errors/app_failure.dart';
import 'package:usta/core/theme/app_colors.dart';
import 'package:usta/data/models/auth_methods.dart';

import '../../helpers/fakes.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> open(
  WidgetTester tester,
  String route, {
  required FakeAccountsRepository accounts,
  FakeIdentity? identity,
}) async {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: testOverrides(
        account: null,
        accountsRepo: accounts,
        identity: identity,
      ),
      child: const UstaApp(),
    ),
  );
  await settle(tester);
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
  await settle(tester);
}

FakeAccountsRepository firebaseServer() =>
    FakeAccountsRepository()
      ..enabledMethods = {SignInMethod.google, SignInMethod.email};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => AppColors.apply(Brightness.light));

  Finder google() => find.widgetWithText(OutlinedButton, 'Google ile devam et');

  testWidgets('without Firebase nothing but the app\'s own sign-in is shown', (
    tester,
  ) async {
    await open(tester, '/login', accounts: FakeAccountsRepository());
    expect(google(), findsNothing);
    expect(find.text('E-posta veya telefon'), findsOneWidget);
    expect(find.text('Şifremi unuttum'), findsNothing);
  });

  testWidgets('Apple and SMS sign-in are never offered', (tester) async {
    await open(
      tester,
      '/login',
      accounts: firebaseServer(),
      identity: FakeIdentity(google: 'g'),
    );
    expect(find.textContaining('Apple'), findsNothing);
    expect(find.textContaining('Telefon numarasıyla'), findsNothing);
    expect(find.textContaining('SMS'), findsNothing);
    expect(google(), findsOneWidget);
  });

  testWidgets(
    'with Firebase the field asks for an e-mail and signs in through it',
    (tester) async {
      final accounts = firebaseServer();
      final identity = FakeIdentity();
      await open(tester, '/login', accounts: accounts, identity: identity);
      expect(find.text('E-posta'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'ayse@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'gizli123');
      await tester.tap(find.widgetWithText(FilledButton, 'Giriş yap'));
      await settle(tester);
      await settle(tester);
      expect(identity.calls, contains('login:ayse@example.com'));
      expect(
        accounts.firebaseCalls.single,
        startsWith('tok-ayse@example.com|'),
      );
    },
  );

  testWidgets(
    'a Firebase user without an Usta account is told to register first',
    (tester) async {
      final accounts = firebaseServer()
        ..nextOutcome = const FederatedOutcome.needsProfile({
          'name': '',
          'email': 'x@y.com',
          'phone': '',
        });
      final identity = FakeIdentity();
      await open(tester, '/login', accounts: accounts, identity: identity);
      await tester.enterText(find.byType(TextFormField).first, 'x@y.com');
      await tester.enterText(find.byType(TextFormField).last, 'gizli123');
      await tester.tap(find.widgetWithText(FilledButton, 'Giriş yap'));
      await settle(tester);
      await settle(tester);
      expect(find.textContaining('Önce kayıt ol'), findsOneWidget);
      expect(identity.calls, contains('signOut'));
    },
  );

  testWidgets('forgot password sends the reset mail', (tester) async {
    final identity = FakeIdentity();
    await open(
      tester,
      '/login',
      accounts: firebaseServer(),
      identity: identity,
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'ayse@example.com',
    );
    await tester.tap(find.text('Şifremi unuttum'));
    await settle(tester);
    expect(identity.calls, contains('reset:ayse@example.com'));
    expect(find.textContaining('gönderdik'), findsOneWidget);
  });

  testWidgets(
    'Google: a new person confirms their name and continues as a customer',
    (tester) async {
      final accounts = firebaseServer()
        ..nextOutcome = const FederatedOutcome.needsProfile({
          'name': 'Ayşe Yılmaz',
          'email': 'ayse@gmail.com',
          'phone': '',
        });
      final identity = FakeIdentity(google: 'gTok');
      await open(tester, '/login', accounts: accounts, identity: identity);
      await tester.tap(google());
      await settle(tester);
      expect(find.text('Hoş geldin'), findsOneWidget);
      expect(find.textContaining('KVKK'), findsOneWidget);
      await tester.tap(find.text('Müşteri olarak devam et'));
      await settle(tester);
      await settle(tester);
      expect(
        accounts.firebaseCalls.last,
        startsWith('gTok|customer|Ayşe Yılmaz'),
      );
      expect(find.text('Hangi ustaya ihtiyacın var?'), findsOneWidget);
    },
  );

  testWidgets('Google: closing the sheet changes nothing', (tester) async {
    final accounts = firebaseServer();
    await open(
      tester,
      '/login',
      accounts: accounts,
      identity: FakeIdentity(google: null),
    );
    await tester.tap(google());
    await settle(tester);
    expect(accounts.firebaseCalls, isEmpty);
    expect(find.text('Giriş yap'), findsWidgets);
  });

  testWidgets('customer sign-up creates the Firebase user, then the account', (
    tester,
  ) async {
    final accounts = firebaseServer();
    final identity = FakeIdentity();
    await open(
      tester,
      '/register/customer',
      accounts: accounts,
      identity: identity,
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Mehmet Yılmaz');
    await tester.enterText(fields.at(1), '05321234567');
    await tester.enterText(fields.at(2), 'mehmet@example.com');
    await tester.enterText(fields.at(3), 'gizli123');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Kayıt ol'));
    await settle(tester);
    await settle(tester);
    expect(identity.calls.take(2), ['create:mehmet@example.com', 'verify']);
    expect(
      accounts.firebaseCalls.single,
      contains('|customer|Mehmet Yılmaz|mehmet@example.com'),
    );
  });

  testWidgets('a sign-up the server refuses removes the new Firebase user', (
    tester,
  ) async {
    final accounts = firebaseServer()
      ..firebaseFailure = const AppFailure(
        FailureKind.invalid,
        'Bu telefon numarası kayıtlı.',
      );
    final identity = FakeIdentity();
    await open(
      tester,
      '/register/customer',
      accounts: accounts,
      identity: identity,
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Mehmet Yılmaz');
    await tester.enterText(fields.at(1), '05321234567');
    await tester.enterText(fields.at(2), 'mehmet@example.com');
    await tester.enterText(fields.at(3), 'gizli123');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Kayıt ol'));
    await settle(tester);
    await settle(tester);
    expect(identity.calls, contains('discard'));
    expect(find.text('Bu telefon numarası kayıtlı.'), findsOneWidget);
  });
}
