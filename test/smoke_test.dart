import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usta/app/app.dart';
import 'package:usta/core/accessibility/ui_scale.dart';
import 'package:usta/core/accessibility/ui_scale_controller.dart';
import 'package:usta/core/theme/app_colors.dart';
import 'package:usta/data/models/user_location.dart';
import 'package:usta/features/location/location_service.dart';
import 'package:usta/core/theme/theme_mode_controller.dart';
import 'package:usta/data/models/account.dart';

import 'helpers/fakes.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

void phoneScreen(WidgetTester tester, {Size size = const Size(1200, 3000)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget app({
  FakeUstaRepository? usta,
  UiScale scale = UiScale.normal,
  Account? account,
  bool onboardingSeen = true,
  AppThemeMode themeMode = AppThemeMode.light,
}) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    ...testOverrides(
      usta:
          usta ??
          FakeUstaRepository(
            pages: [
              [fakeUsta(1, premium: true), fakeUsta(2)],
            ],
          ),
      account: account,
      onboardingSeen: onboardingSeen,
    ),
    initialUiScaleProvider.overrideWithValue(scale),
    initialThemeModeProvider.overrideWithValue(themeMode),
  ],
  child: const UstaApp(),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => AppColors.apply(Brightness.light));

  testWidgets(
    'app boots, discovery loads, provider detail opens with its sections',
    (tester) async {
      phoneScreen(tester);
      await tester.pumpWidget(app());
      await settle(tester);

      // Boot + discovery
      expect(find.text('Hangi ustaya ihtiyacın var?'), findsOneWidget);
      expect(find.text('Ana Sayfa'), findsOneWidget);
      expect(find.text('Yıldız Elektrik 1'), findsOneWidget);

      // Open provider detail
      await tester.ensureVisible(find.text('Yıldız Elektrik 1'));
      await tester.pump();
      await tester.tap(find.text('Yıldız Elektrik 1'));
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));

      // The address comes first, then the price list, work photos and reviews.
      final list = find.byType(Scrollable).last;
      expect(find.text('Adres'), findsOneWidget);
      expect(find.text('Yol Tarifi'), findsOneWidget);
      final addressTop = tester.getTopLeft(find.text('Adres')).dy;
      await tester.scrollUntilVisible(
        find.text('Fiyat listesi'),
        300,
        scrollable: list,
      );
      expect(find.text('Priz değişimi'), findsOneWidget);
      expect(find.text('150 – 300 ₺'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Yapılan işler'),
        300,
        scrollable: list,
      );
      expect(find.text('Henüz iş fotoğrafı eklenmemiş.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Çok memnun kaldım.'),
        300,
        scrollable: list,
      );
      expect(find.text('Yorumlar (1)'), findsOneWidget);
      expect(
        addressTop,
        lessThan(tester.getTopLeft(find.text('Yorumlar (1)')).dy),
      );

      // One primary action, one secondary that opens the grouped options.
      expect(find.text('Ara'), findsOneWidget);
      await tester.tap(find.text('Mesaj Gönder'));
      await settle(tester);
      expect(find.text('Uygulamadan yaz'), findsOneWidget);
      expect(find.text('WhatsApp’tan yaz'), findsOneWidget);
      expect(find.text('SMS ile yaz'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10)); // dismiss the sheet
      await settle(tester);

      // Back to the list
      await tester.tap(find.byTooltip('Geri'));
      await settle(tester);
      expect(find.text('Yıldız Elektrik 1'), findsOneWidget);
    },
  );

  testWidgets(
    'the first screen shows the services and two ustas without scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532); // 390 x 844 dp
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: testOverrides(
            usta: FakeUstaRepository(
              pages: [
                [fakeUsta(1), fakeUsta(2), fakeUsta(3)],
              ],
            ),
            location: FakeLocationService(
              const LocationFound(UserLocation(lat: 40.99, lng: 29.03)),
            ),
          ),
          child: const UstaApp(),
        ),
      );
      await settle(tester);
      await settle(tester);

      final navTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
      expect(find.text('Elektrik'), findsWidgets);
      final second = tester.getRect(find.text('Yıldız Elektrik 2'));
      expect(
        second.bottom,
        lessThan(navTop),
        reason:
            'the second usta card starts and its title fits above the tab bar',
      );
    },
  );

  testWidgets('three real tabs, no Map tab; guests are invited to sign in', (
    tester,
  ) async {
    phoneScreen(tester);
    await tester.pumpWidget(app());
    await settle(tester);

    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Taleplerim'), findsOneWidget);
    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.text('Harita'), findsNothing);
    expect(find.text('Profil'), findsNothing);

    await tester.tap(find.text('Taleplerim'));
    await settle(tester);
    expect(find.text('Taleplerini görmek için giriş yap'), findsOneWidget);

    await tester.tap(find.text('Ayarlar'));
    await settle(tester);
    expect(find.text('Arayüz Boyutu'), findsOneWidget);
    expect(find.text('Görünüm'), findsOneWidget);
    expect(find.text('Giriş yap'), findsWidgets);

    await tester.tap(find.text('Ana Sayfa'));
    await settle(tester);
    expect(find.text('Hangi ustaya ihtiyacın var?'), findsOneWidget);
  });

  testWidgets(
    'a signed-in customer sees the profile button and their requests',
    (tester) async {
      phoneScreen(tester);
      await tester.pumpWidget(app(account: testCustomer));
      await settle(tester);

      expect(find.bySemanticsLabel('Bildirimler'), findsOneWidget);
      expect(
        find.text('AY'),
        findsOneWidget,
        reason: 'profile button initials',
      );

      await tester.tap(find.text('Taleplerim'));
      await settle(tester);
      expect(find.text('Henüz talebin yok'), findsOneWidget);

      await tester.tap(find.text('Ayarlar'));
      await settle(tester);
      expect(find.text('Hesabım'), findsOneWidget);
      expect(find.text('Verilerimi indir'), findsOneWidget);
      expect(find.text('Hesabımı sil'), findsOneWidget);
    },
  );

  testWidgets('first launch shows the intro, then the two ways to sign up', (
    tester,
  ) async {
    phoneScreen(tester);
    await tester.pumpWidget(app(onboardingSeen: false));
    await settle(tester);

    expect(find.text('Aradığın usta, yakınında'), findsOneWidget);
    await tester.tap(find.text('Devam'));
    await settle(tester);
    await tester.tap(find.text('Devam'));
    await settle(tester);

    expect(find.text('Usta arıyorum'), findsOneWidget);
    expect(find.text('Ustayım, iş arıyorum'), findsOneWidget);

    await tester.tap(find.text('Şimdilik göz at'));
    await settle(tester);
    expect(find.text('Hangi ustaya ihtiyacın var?'), findsOneWidget);
  });

  testWidgets('choosing a larger UI size grows controls and is remembered', (
    tester,
  ) async {
    phoneScreen(tester);
    await tester.pumpWidget(app());
    await settle(tester);
    expect(tester.getSize(find.byType(NavigationBar)).height, 68);

    await tester.tap(find.text('Ayarlar'));
    await settle(tester);
    await tester.tap(find.text('Büyük'));
    await settle(tester);

    expect(tester.getSize(find.byType(NavigationBar)).height, 76);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ui_scale'), 'large');
  });

  testWidgets('dark theme switches every colour live and is remembered', (
    tester,
  ) async {
    phoneScreen(tester);
    await tester.pumpWidget(app());
    await settle(tester);
    expect(AppColors.isDark, isFalse);
    final lightBackground = AppColors.background;

    await tester.tap(find.text('Ayarlar'));
    await settle(tester);
    await tester.ensureVisible(find.text('Koyu'));
    await tester.pump();
    await tester.tap(find.text('Koyu'));
    await settle(tester);

    expect(AppColors.isDark, isTrue);
    expect(AppColors.background, isNot(lightBackground));
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor ??
          Theme.of(tester.element(find.byType(Scaffold).first))
              .scaffoldBackgroundColor,
      AppColors.background,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');

    // And back, so a person is never stuck in a palette they did not want.
    await tester.ensureVisible(find.text('Açık'));
    await tester.pump();
    await tester.tap(find.text('Açık'));
    await settle(tester);
    expect(AppColors.isDark, isFalse);
  });

  testWidgets('the saved dark theme is used from the first frame', (
    tester,
  ) async {
    phoneScreen(tester);
    await tester.pumpWidget(app(themeMode: AppThemeMode.dark));
    await settle(tester);
    expect(AppColors.isDark, isTrue);
    expect(find.text('Hangi ustaya ihtiyacın var?'), findsOneWidget);
  });

  for (final scale in [UiScale.large, UiScale.extraLarge]) {
    testWidgets(
      '${scale.label} UI with a large system font fits a small phone without overflow',
      (tester) async {
        phoneScreen(tester, size: const Size(960, 1760)); // 320 x 587 dp
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        // Collect layout errors with their widget path so a failure names the culprit.
        final errors = <String>[];
        final original = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(
          '${d.exceptionAsString()} @ ${d.informationCollector?.call().map((e) => e.toString()).join(' ')}',
        );

        try {
          await tester.pumpWidget(app(scale: scale));
          await settle(tester);
          expect(errors, isEmpty);
          expect(find.text('Hangi ustaya ihtiyacın var?'), findsOneWidget);

          // Bring the first provider into view on this small screen, then open it.
          await tester.scrollUntilVisible(
            find.text('Yıldız Elektrik 1'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await settle(tester);
          expect(errors, isEmpty);

          await tester.tap(find.text('Yıldız Elektrik 1').first);
          await settle(tester);
          await tester.pump(const Duration(milliseconds: 400));
          expect(errors, isEmpty);
          expect(find.text('Ara'), findsOneWidget);
          expect(find.text('Mesaj Gönder'), findsOneWidget);
          await tester.drag(
            find.byType(ListView).first,
            const Offset(0, -3000),
          );
          await settle(tester);
          expect(errors, isEmpty);
        } finally {
          FlutterError.onError = original;
        }
      },
    );
  }
}
