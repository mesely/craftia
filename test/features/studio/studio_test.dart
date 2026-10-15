import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usta/app/app.dart';
import 'package:usta/core/accessibility/ui_scale.dart';
import 'package:usta/core/accessibility/ui_scale_controller.dart';
import 'package:usta/core/theme/app_colors.dart';
import 'package:usta/core/widgets/art_image.dart';
import 'package:usta/data/models/account.dart';
import 'package:usta/data/models/user_location.dart';
import 'package:usta/data/providers.dart';
import 'package:usta/features/discovery/discovery_providers.dart';
import 'package:usta/features/location/location_service.dart';
import 'package:usta/features/studio/profile_completeness.dart';

import '../../helpers/fakes.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 100));
}

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget app({
  Account? account,
  FakeUstaRepository? usta,
  FakeLocationService? location,
  FakePromotionsRepository? promotions,
}) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    ...testOverrides(
      usta: usta,
      account: account,
      location: location,
      promotions: promotions,
    ),
  ],
  child: const UstaApp(),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => AppColors.apply(Brightness.light));

  group('ProfileCompleteness', () {
    test('lists what is missing and counts what is done', () {
      final bare = ProfileCompleteness.of(fakeUsta(1, withPrices: false));
      expect(bare.complete, isFalse);
      expect(
        bare.missing.map((i) => i.id),
        containsAll(['photo', 'prices', 'work']),
      );
      expect(bare.items.firstWhere((i) => i.id == 'about').done, isTrue);
      expect(bare.items.firstWhere((i) => i.id == 'place').done, isTrue);
      expect(bare.fraction, closeTo(2 / 5, 0.001));
    });
  });

  group('an usta signed in', () {
    testWidgets(
      'gets a panel, requests, their page and settings: no customer search',
      (tester) async {
        phone(tester);
        await tester.pumpWidget(app(account: testUsta));
        await settle(tester);

        expect(find.text('Panel'), findsOneWidget);
        expect(find.text('Talepler'), findsWidgets);
        expect(find.text('Sayfam'), findsOneWidget);
        expect(find.text('Ayarlar'), findsOneWidget);
        expect(find.text('Merhaba, Ali'), findsOneWidget);
        expect(find.text('Hangi ustaya ihtiyacın var?'), findsNothing);
        expect(find.text('Öne çık, daha çok iş al'), findsOneWidget);
        expect(find.text('Sayfanı tamamla'), findsOneWidget);
      },
    );

    testWidgets(
      'the promotion plans show length, price and the cheaper day rate',
      (tester) async {
        phone(tester);
        final promotions = FakePromotionsRepository();
        await tester.pumpWidget(app(account: testUsta, promotions: promotions));
        await settle(tester);

        await tester.tap(find.text('Planları gör'));
        await settle(tester);
        expect(find.text('1 hafta'), findsOneWidget);
        expect(find.text('1 ay'), findsOneWidget);
        expect(find.text('3 ay'), findsOneWidget);
        expect(find.text('99 ₺'), findsOneWidget);
        expect(find.text('249 ₺'), findsOneWidget);
        expect(find.text('599 ₺'), findsOneWidget);
        expect(find.textContaining('Test sürümü'), findsOneWidget);

        await tester.tap(find.text('3 ay'));
        await settle(tester);
        await tester.tap(find.text('3 ay öne çık'));
        await settle(tester);
        expect(promotions.bought, ['quarter']);
        expect(find.text('Öne çıkıyorsun'), findsOneWidget);
      },
    );

    testWidgets(
      'on their own page there is no Ara / Mesaj Gönder, only editing',
      (tester) async {
        phone(tester);
        await tester.pumpWidget(app(account: testUsta));
        await settle(tester);

        await tester.ensureVisible(find.text('Müşteri gözüyle sayfam'));
        await tester.pump();
        await tester.tap(find.text('Müşteri gözüyle sayfam'));
        await settle(tester);
        expect(
          find.text('Bu senin sayfan. Müşteriler böyle görüyor.'),
          findsOneWidget,
        );
        expect(find.text('Sayfamı düzenle'), findsOneWidget);
        expect(find.text('Mesaj Gönder'), findsNothing);
        expect(find.text('Ara'), findsNothing);
      },
    );

    testWidgets('never sees their own listing in search results', (
      tester,
    ) async {
      phone(tester);
      final repo = FakeUstaRepository(
        pages: [
          [fakeUsta(2)],
        ],
      );
      // The customer search runs for guests and customers; check the query it sends for an usta.
      final container = ProviderContainer(
        overrides: testOverrides(usta: repo, account: testUsta),
      );
      addTearDown(container.dispose);
      await container
          .read(ustaRepositoryProvider)
          .fetchPage(container.read(providerQueryProvider), 1);
      expect(repo.queries.single.excludeId, 'u1');
    });
  });

  for (final scale in [UiScale.large, UiScale.extraLarge]) {
    testWidgets(
      'usta screens fit a small phone at ${scale.label} with a large system font',
      (tester) async {
        tester.view.physicalSize = const Size(960, 1760);
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final errors = <String>[];
        final original = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(
          '${d.exceptionAsString()} @ ${d.informationCollector?.call().map((e) => e.toString()).join(' ')}',
        );
        try {
          await tester.pumpWidget(
            ProviderScope(
              retry: (_, _) => null,
              overrides: [
                ...testOverrides(account: testUsta),
                initialUiScaleProvider.overrideWithValue(scale),
              ],
              child: const UstaApp(),
            ),
          );
          await settle(tester);
          expect(errors, isEmpty);
          for (final tab in ['Talepler', 'Sayfam', 'Ayarlar', 'Panel']) {
            await tester.tap(find.text(tab).last);
            await settle(tester);
            expect(errors, isEmpty, reason: tab);
          }
        } finally {
          FlutterError.onError = original;
        }
      },
    );
  }

  group('dark theme art', () {
    testWidgets('illustrations are re-coloured on a deep blue plate', (
      tester,
    ) async {
      AppColors.apply(Brightness.dark);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ArtImage('assets/services/elektrik.webp')),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(ArtImage),
          matching: find.byType(ColorFiltered),
        ),
        findsOneWidget,
      );
      expect(AppColors.artPlate, isNot(const Color(0xFFFFFFFF)));
    });

    testWidgets('light theme keeps the paper white', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ArtImage('assets/services/elektrik.webp')),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(ArtImage),
          matching: find.byType(ColorFiltered),
        ),
        findsNothing,
      );
    });
  });

  group('usta registration', () {
    testWidgets(
      'fills place from the phone, saves coordinates, and signs the new usta in',
      (tester) async {
        phone(tester);
        final accounts = FakeAccountsRepository();
        await tester.pumpWidget(
          ProviderScope(
            retry: (_, _) => null,
            overrides: testOverrides(
              account: null,
              accountsRepo: accounts,
              location: FakeLocationService(
                const LocationFound(UserLocation(lat: 38.46, lng: 27.2)),
              ),
            ),
            child: const UstaApp(),
          ),
        );
        await settle(tester);
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .go('/register/provider');
        await settle(tester);

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Ali Usta');
        await tester.enterText(fields.at(1), '05329998877');
        await tester.enterText(fields.at(2), 'ali@example.com');
        await tester.enterText(fields.at(3), 'gizli123');
        await tester.tap(find.text('Devam'));
        await settle(tester);

        await tester.enterText(
          find.byType(TextFormField).first,
          'Ali Elektrik',
        );
        await tester.tap(find.text('Konumumu kullan'));
        await settle(tester);
        await settle(tester);
        expect(find.text('İzmir'), findsWidgets);
        await tapVisible(tester, find.text('Elektrik').first);
        await tapVisible(tester, find.text('Dükkânım ya da ofisim var'));
        await settle(tester);
        await tester.enterText(
          find.byType(TextFormField).last,
          'Yıllardır bölgede elektrik işleri yapıyorum, keşif ücretsiz.',
        );
        await tapVisible(tester, find.text('Devam'));
        await settle(tester);

        await tapVisible(tester, find.byType(Checkbox));
        await settle(tester);
        await tapVisible(tester, find.text('Kaydı tamamla'));
        await settle(tester);
        await settle(tester);

        final application = accounts.applications.single;
        expect(application.city, 'İzmir');
        expect(application.district, 'Karşıyaka');
        expect(application.address, contains('Bostanlı'));
        expect(application.lat, closeTo(38.46, 0.001));
        expect(application.lng, closeTo(27.2, 0.001));
        expect(accounts.accounts.single.role, AccountRole.provider);
      },
    );
  });
}
