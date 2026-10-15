import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usta/app/app.dart';
import 'package:usta/core/accessibility/ui_scale.dart';
import 'package:usta/core/accessibility/ui_scale_controller.dart';

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

Widget app({FakeUstaRepository? usta, UiScale scale = UiScale.normal}) =>
    ProviderScope(
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
        ),
        initialUiScaleProvider.overrideWithValue(scale),
      ],
      child: const UstaApp(),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
      await tester.tap(find.text('Yıldız Elektrik 1'));
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Fiyat listesi'), findsOneWidget);
      expect(find.text('Priz değişimi'), findsOneWidget);
      expect(find.text('150 – 300 ₺'), findsOneWidget);
      expect(find.text('Yapılan işler'), findsOneWidget);
      expect(find.text('Henüz iş fotoğrafı eklenmemiş.'), findsOneWidget);
      expect(find.text('Yorumlar (1)'), findsOneWidget);
      expect(find.text('Çok memnun kaldım.'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -2500));
      await settle(tester);
      expect(find.text('Adres'), findsOneWidget);
      expect(find.text('Yol Tarifi'), findsOneWidget);

      // One primary action, one secondary that opens the grouped options.
      expect(find.text('Ara'), findsOneWidget);
      await tester.tap(find.text('Mesaj Gönder'));
      await settle(tester);
      expect(find.text('Hizmet talebi gönder'), findsOneWidget);
      expect(find.text('SMS ile yaz'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10)); // dismiss the sheet
      await settle(tester);

      // Back to the list
      await tester.tap(find.byTooltip('Geri'));
      await settle(tester);
      expect(find.text('Hangi ustaya ihtiyacın var?'), findsOneWidget);
    },
  );

  testWidgets('navigation has three real tabs and no Map tab', (tester) async {
    phoneScreen(tester);
    await tester.pumpWidget(app());
    await settle(tester);

    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.text('Harita'), findsNothing);

    await tester.tap(find.text('Taleplerim'));
    await settle(tester);
    expect(find.text('Henüz talebin yok'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await settle(tester);
    expect(find.text('Arayüz Boyutu'), findsOneWidget);
    expect(find.text('Kullanıcı sözleşmesi'), findsOneWidget);

    await tester.tap(find.text('Ana Sayfa'));
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

    await tester.tap(find.text('Profil'));
    await settle(tester);
    await tester.tap(find.text('Büyük'));
    await settle(tester);

    expect(tester.getSize(find.byType(NavigationBar)).height, 76);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ui_scale'), 'large');
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
