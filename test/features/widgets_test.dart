import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:usta/core/errors/app_failure.dart';
import 'package:usta/core/theme/app_theme.dart';
import 'package:usta/data/models/filter_state.dart';
import 'package:usta/data/models/user_location.dart';
import 'package:usta/features/discovery/discovery_screen.dart';
import 'package:usta/features/location/location_service.dart';
import 'package:usta/features/provider/widgets/usta_card.dart';
import 'package:usta/features/provider/widgets/usta_results.dart';

import '../helpers/fakes.dart';

Widget host(Widget child, {List<Override>? overrides}) => ProviderScope(
  overrides: overrides ?? testOverrides(),
  child: MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  ),
);

void tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  group('UstaCard', () {
    testWidgets('shows the evaluation essentials', (tester) async {
      tallScreen(tester);
      await tester.pumpWidget(
        host(
          UstaCard(
            usta: fakeUsta(1, premium: true),
            userLocation: const UserLocation(lat: 40.99, lng: 29.03),
          ),
        ),
      );

      expect(find.text('Yıldız Elektrik 1'), findsOneWidget);
      expect(find.textContaining('Elektrikçi'), findsOneWidget);
      expect(
        find.text('Kadıköy, İstanbul'),
        findsNothing,
      ); // merged into the subtitle line
      expect(find.textContaining('Kadıköy, İstanbul'), findsOneWidget);
      expect(find.text('4,5'), findsOneWidget);
      expect(find.text('(12)'), findsOneWidget);
      expect(find.text('150 ₺'), findsOneWidget);
      expect(find.text('Öne çıkan'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('doğrulanmış')), findsOneWidget);
      expect(find.text('Ara'), findsOneWidget);
    });

    testWidgets('a provider without ratings or prices degrades gracefully', (
      tester,
    ) async {
      tallScreen(tester);
      await tester.pumpWidget(
        host(UstaCard(usta: fakeUsta(2, rating: 0, withPrices: false))),
      );
      expect(find.text('Yeni'), findsOneWidget);
      expect(find.text('Fiyat için arayın'), findsOneWidget);
    });
  });

  group('UstaResultsSliver states', () {
    Widget results(FakeUstaRepository repo, {VoidCallback? onClear}) => host(
      CustomScrollView(
        slivers: [
          UstaResultsSliver(
            query: const ProviderQuery(filters: FilterState()),
            onClearFilters: onClear,
          ),
        ],
      ),
      overrides: testOverrides(usta: repo),
    );

    testWidgets('loading shows skeleton cards, then the list', (tester) async {
      tallScreen(tester);
      final gate = Completer<void>();
      await tester.pumpWidget(
        results(
          FakeUstaRepository(
            pages: [
              [fakeUsta(1), fakeUsta(2)],
            ],
            gate: gate,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(UstaListSkeleton), findsOneWidget);
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'no full-screen spinner',
      );

      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(UstaListSkeleton), findsNothing);
      expect(find.text('Yıldız Elektrik 1'), findsOneWidget);
      expect(find.text('Yıldız Elektrik 2'), findsOneWidget);
      expect(find.text('2 usta gösterildi'), findsOneWidget);
    });

    testWidgets('empty state offers to clear filters', (tester) async {
      tallScreen(tester);
      var cleared = false;
      await tester.pumpWidget(
        results(
          FakeUstaRepository(pages: const [[]]),
          onClear: () => cleared = true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Bu filtrelere uygun usta bulamadık.'), findsOneWidget);
      await tester.tap(find.text('Filtreleri temizle'));
      expect(cleared, isTrue);
    });

    testWidgets('error state shows a human message and can retry', (
      tester,
    ) async {
      tallScreen(tester);
      final repo = FakeUstaRepository(error: AppFailure.network);
      await tester.pumpWidget(results(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Bağlantı yok'), findsOneWidget);
      expect(
        find.textContaining('İnternet bağlantına ulaşamadık'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tekrar dene'));
      await tester.pump();
      expect(repo.queries.length, 2);
    });
  });

  group('Discovery filters', () {
    testWidgets('tapping chips and tiles re-queries with the new filters', (
      tester,
    ) async {
      tallScreen(tester);
      final repo = FakeUstaRepository(
        pages: [
          [fakeUsta(1)],
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(usta: repo),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const DiscoveryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(repo.queries.last.filters.mainType, 'TECHNICAL');

      await tester.tap(find.text('Su Tesisat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(repo.queries.last.filters.subType, 'Su Tesisatçısı');

      await tester.tap(find.text('Puan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(repo.queries.last.filters.sortMode, SortMode.rating);

      await tester.tap(find.text('Hizmet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(repo.queries.last.filters.mainType, 'LIFE');
      expect(
        repo.queries.last.filters.subType,
        isNull,
        reason: 'sub-type resets with the category',
      );
    });

    testWidgets(
      'without location permission the screen still works and explains why',
      (tester) async {
        tallScreen(tester);
        await tester.pumpWidget(
          ProviderScope(
            overrides: testOverrides(
              location: FakeLocationService(const LocationPermissionDenied()),
            ),
            child: MaterialApp(
              theme: AppTheme.light,
              home: const DiscoveryScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Yıldız Elektrik 1'), findsOneWidget);
        expect(find.textContaining('konum izni gerekiyor'), findsOneWidget);
        expect(find.text('İzin ver'), findsOneWidget);
      },
    );
  });
}
