import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usta/core/theme/app_theme.dart';
import 'package:usta/data/models/usta.dart';
import 'package:usta/features/map/map_screen.dart';
import 'package:usta/features/map/map_surface.dart';

import '../helpers/fakes.dart';

void main() {
  group('MapPin', () {
    test('only providers with a real position become pins', () {
      expect(MapPin.fromUsta(fakeUsta(1)), isNotNull);
      const noPosition = Usta(
        id: 'x',
        businessName: 'Konumsuz',
        phoneNumber: '1',
        mainType: 'TECHNICAL',
        subType: 'Elektrikçi',
        city: 'Ankara',
        district: 'Çankaya',
        address: '',
      );
      expect(MapPin.fromUsta(noPosition), isNull);
    });

    test('featured providers are flagged', () {
      expect(MapPin.fromUsta(fakeUsta(2, premium: true))!.isFeatured, isTrue);
    });
  });

  group('MapScreen', () {
    Widget host(FakeUstaRepository repo) => ProviderScope(
      overrides: testOverrides(usta: repo),
      child: MaterialApp(theme: AppTheme.light, home: const MapScreen()),
    );

    void tall(WidgetTester tester) {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    testWidgets('requests the nearest 50 and shows how many are on the map', (
      tester,
    ) async {
      tall(tester);
      final repo = FakeUstaRepository(
        pages: [
          [fakeUsta(1), fakeUsta(2), fakeUsta(3)],
        ],
      );
      await tester.pumpWidget(host(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(repo.queries.first.pageSize, 50);
      expect(find.text('3 usta'), findsOneWidget);
      expect(find.text('Harita'), findsOneWidget);
    });

    testWidgets('empty result explains itself and offers to clear filters', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(host(FakeUstaRepository(pages: const [[]])));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Haritada gösterecek usta bulamadık.'), findsOneWidget);
      expect(find.text('Filtreleri temizle'), findsOneWidget);
    });

    testWidgets('a network failure shows the retryable error state', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(host(FakeUstaRepository(error: Exception('x'))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Tekrar dene'), findsOneWidget);
    });
  });
}
