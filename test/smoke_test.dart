import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usta/app/app.dart';

import 'helpers/fakes.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets(
    'app boots, discovery loads, provider detail opens with its sections',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: testOverrides(
            usta: FakeUstaRepository(
              pages: [
                [fakeUsta(1, premium: true), fakeUsta(2)],
              ],
            ),
          ),
          child: const UstaApp(),
        ),
      );
      await settle(tester);

      // Boot + discovery
      expect(find.textContaining('Hangi ustaya'), findsOneWidget);
      expect(find.text('Keşfet'), findsOneWidget);
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
      expect(find.text('Ara'), findsOneWidget);
      expect(find.text('Talep gönder'), findsOneWidget);

      // Back to the list
      await tester.tap(find.byTooltip('Geri'));
      await settle(tester);
      expect(find.text('Yıldız Elektrik 2'), findsOneWidget);
    },
  );

  testWidgets('bottom tabs navigate between the five destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: testOverrides(),
        child: const UstaApp(),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Harita'));
    await settle(tester);
    expect(find.text('1 usta'), findsOneWidget);

    await tester.tap(find.text('Ara').last);
    await settle(tester);
    expect(find.text('Usta, hizmet veya semt ara'), findsOneWidget);
    expect(find.text('Elektrik, Isı & Su'), findsOneWidget);

    await tester.tap(find.text('Taleplerim'));
    await settle(tester);
    expect(find.text('Henüz talebin yok'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await settle(tester);
    expect(find.text('Kullanıcı sözleşmesi'), findsOneWidget);
  });
}
