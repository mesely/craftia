import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usta/core/constants/services.dart';
import 'package:usta/core/errors/app_failure.dart';
import 'package:usta/core/theme/app_theme.dart';
import 'package:usta/data/models/filter_state.dart';
import 'package:usta/data/models/user_location.dart';
import 'package:usta/features/discovery/discovery_screen.dart';
import 'package:usta/features/discovery/service_tile.dart';
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

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

/// The picture tile for a service (the same words also appear on provider cards).
Finder tile(String label) =>
    find.descendant(of: find.byType(ServiceTile), matching: find.text(label));

Future<void> tapTile(WidgetTester tester, String label) async {
  await tester.ensureVisible(tile(label));
  await tester.pump();
  await tester.tap(tile(label));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('UstaCard', () {
    testWidgets('shows the evaluation essentials and one clear action', (
      tester,
    ) async {
      tallScreen(tester);
      await tester.pumpWidget(
        host(
          UstaCard(
            usta: fakeUsta(1, premium: true),
            userLocation: const UserLocation(lat: 40.99, lng: 29.06),
          ),
        ),
      );

      expect(find.text('Yıldız Elektrik 1'), findsOneWidget);
      expect(find.text('4,5'), findsOneWidget);
      expect(find.text('(12 yorum)'), findsOneWidget);
      expect(find.textContaining('Kadıköy, İstanbul'), findsOneWidget);
      expect(find.textContaining(' km'), findsOneWidget);
      expect(find.textContaining('150 ₺'), findsOneWidget);
      expect(find.text('Öne çıkan'), findsOneWidget);
      expect(find.text('Doğrulanmış'), findsOneWidget);
      expect(find.textContaining('Başlangıç'), findsOneWidget);
      expect(
        find.text('Ara'),
        findsNothing,
        reason: 'contact actions live on the detail page, not on every card',
      );
    });

    testWidgets('a provider without ratings or prices degrades gracefully', (
      tester,
    ) async {
      tallScreen(tester);
      await tester.pumpWidget(
        host(UstaCard(usta: fakeUsta(2, rating: 0, withPrices: false))),
      );
      expect(find.text('Yeni usta'), findsNothing);
      expect(find.text('Fiyat için arayın'), findsOneWidget);
      expect(find.textContaining(' km'), findsNothing);
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

      expect(find.text('İnternet bağlantısı yok'), findsOneWidget);
      expect(
        find.textContaining('İnternet bağlantına ulaşamadık'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tekrar dene'));
      await tester.pump();
      expect(repo.queries.length, 2);
    });

    testWidgets('a server failure says so in plain Turkish, no raw error', (
      tester,
    ) async {
      tallScreen(tester);
      await tester.pumpWidget(
        results(FakeUstaRepository(error: Exception('500 Internal'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Şu anda ustaları yükleyemedik'), findsOneWidget);
      expect(find.textContaining('500'), findsNothing);
    });
  });

  group('Discovery', () {
    Widget discovery(FakeUstaRepository repo, {FakeLocationService? loc}) =>
        ProviderScope(
          overrides: testOverrides(usta: repo, location: loc),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: DiscoveryScreen()),
          ),
        );

    FakeUstaRepository oneUsta() => FakeUstaRepository(
      pages: [
        [fakeUsta(1)],
      ],
    );

    testWidgets('one clear way to filter: the service tiles, and no map', (
      tester,
    ) async {
      tallScreen(tester);
      final repo = oneUsta();
      await tester.pumpWidget(discovery(repo));
      await settle(tester);

      expect(repo.queries.last.filters.subType, isNull);
      expect(find.text('Hangi ustaya ihtiyacın var?'), findsOneWidget);
      for (final service in kServices) {
        expect(tile(service.label), findsOneWidget);
      }
      expect(find.text('Tüm hizmetler'), findsNothing);
      expect(find.text('Filtrele'), findsNothing);
      expect(find.textContaining('Harita'), findsNothing);
      expect(find.text('Yıldız Elektrik 1'), findsOneWidget);
    });

    testWidgets('a tile filters, a second tap clears it', (tester) async {
      tallScreen(tester);
      final repo = oneUsta();
      await tester.pumpWidget(discovery(repo));
      await settle(tester);

      await tapTile(tester, 'Su Tesisatı');
      await settle(tester);
      expect(repo.queries.last.filters.mainType, 'TECHNICAL');
      expect(repo.queries.last.filters.subType, 'Su Tesisatçısı');

      await tapTile(tester, 'Temizlik');
      await settle(tester);
      expect(repo.queries.last.filters.mainType, 'LIFE');
      expect(repo.queries.last.filters.subType, 'Ev Temizliği');

      await tapTile(tester, 'Temizlik');
      await settle(tester);
      expect(repo.queries.last.filters.subType, isNull);
    });

    testWidgets('sorting sits with the results and re-queries', (tester) async {
      tallScreen(tester);
      final repo = oneUsta();
      await tester.pumpWidget(discovery(repo));
      await settle(tester);

      await tester.tap(find.text('En yakın').first);
      await settle(tester);
      await tester.tap(find.text('En yüksek puan').last);
      await settle(tester);
      expect(repo.queries.last.filters.sortMode, SortMode.rating);
      expect(find.text('Puana göre'), findsOneWidget);
    });

    testWidgets('searching replaces the service and can be cleared', (
      tester,
    ) async {
      tallScreen(tester);
      final repo = oneUsta();
      await tester.pumpWidget(discovery(repo));
      await settle(tester);
      await tapTile(tester, 'Elektronik');
      await settle(tester);
      expect(repo.queries.last.filters.mainType, 'TECH');

      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'kombi');
      await tester.pump(const Duration(milliseconds: 500));
      await settle(tester);
      expect(repo.queries.last.filters.query, 'kombi');
      expect(repo.queries.last.filters.subType, isNull);

      await tester.tap(find.byTooltip('Aramayı temizle'));
      await settle(tester);
      expect(repo.queries.last.filters.query, '');
    });

    testWidgets('the location row names the district once the phone knows', (
      tester,
    ) async {
      tallScreen(tester);
      await tester.pumpWidget(
        discovery(
          oneUsta(),
          loc: FakeLocationService(
            const LocationFound(UserLocation(lat: 38.46, lng: 27.2)),
          ),
        ),
      );
      await settle(tester);
      await settle(tester);
      expect(find.text('Karşıyaka, İzmir'), findsOneWidget);
      expect(
        find.text('Konumumu kullan'),
        findsNothing,
        reason: 'no notice when location works',
      );
    });

    testWidgets(
      'without location permission the app still works and explains why',
      (tester) async {
        tallScreen(tester);
        await tester.pumpWidget(
          discovery(
            oneUsta(),
            loc: FakeLocationService(const LocationPermissionDenied()),
          ),
        );
        await settle(tester);

        expect(find.text('Yıldız Elektrik 1'), findsOneWidget);
        expect(find.textContaining('konumunu kullanabiliriz'), findsOneWidget);
        expect(find.text('Konumumu kullan'), findsOneWidget);
      },
    );
  });
}
