import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usta/app/app.dart';
import 'package:usta/core/theme/app_colors.dart';
import 'package:usta/data/models/auth_methods.dart';
import 'package:usta/features/auth/federated_sign_in.dart';

import '../../helpers/fakes.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> openLogin(
  WidgetTester tester, {
  required FakeAccountsRepository accounts,
  FakeFederatedSignIn? federated,
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        ...testOverrides(account: null, accountsRepo: accounts),
        if (federated != null)
          federatedSignInProvider.overrideWithValue(federated),
      ],
      child: const UstaApp(),
    ),
  );
  await settle(tester);
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/login');
  await settle(tester);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => AppColors.apply(Brightness.light));

  Finder button(String label) => find.widgetWithText(OutlinedButton, label);

  testWidgets(
    'Google, Apple and SMS are built but switched off until the server enables them',
    (tester) async {
      await openLogin(tester, accounts: FakeAccountsRepository());
      for (final m in SignInMethod.values) {
        final b = tester.widget<OutlinedButton>(button(m.label));
        expect(b.onPressed, isNull, reason: m.label);
      }
      expect(find.textContaining('yakında açılacak'), findsOneWidget);
    },
  );

  testWidgets(
    'an enabled method asks Firebase for a token and signs the person in',
    (tester) async {
      final accounts = FakeAccountsRepository()
        ..enabledMethods = {SignInMethod.google};
      final federated = FakeFederatedSignIn('tok1');
      await openLogin(tester, accounts: accounts, federated: federated);

      expect(
        tester.widget<OutlinedButton>(button('Google ile devam et')).onPressed,
        isNotNull,
      );
      expect(
        tester.widget<OutlinedButton>(button('Apple ile devam et')).onPressed,
        isNull,
      );

      await tester.tap(button('Google ile devam et'));
      await settle(tester);
      await settle(tester);
      expect(federated.asked, [SignInMethod.google]);
      expect(accounts.firebaseCalls.single, startsWith('tok1|'));
      expect(find.text('Hangi ustaya ihtiyacın var?'), findsOneWidget);
    },
  );

  testWidgets(
    'a new person is asked for their name, then continues as a customer',
    (tester) async {
      final accounts = FakeAccountsRepository()
        ..enabledMethods = {SignInMethod.phone}
        ..nextOutcome = const FederatedOutcome.needsProfile({
          'name': '',
          'email': '',
          'phone': '+905320000000',
        });
      await openLogin(
        tester,
        accounts: accounts,
        federated: FakeFederatedSignIn('tokSms'),
      );
      await tester.tap(button('Telefon numarasıyla devam et'));
      await settle(tester);
      expect(find.text('Hoş geldin'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Mehmet Yılmaz');
      await tester.tap(find.text('Müşteri olarak devam et'));
      await settle(tester);
      await settle(tester);
      expect(accounts.firebaseCalls.last, 'tokSms|customer|Mehmet Yılmaz');
    },
  );

  testWidgets(
    'without the Firebase files the default sign-in says it is not active',
    (tester) async {
      await expectLater(
        const NotConfiguredFederatedSignIn().idToken(SignInMethod.google),
        throwsA(anything),
      );
    },
  );
}
