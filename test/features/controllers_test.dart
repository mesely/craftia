import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usta/core/constants/services.dart';
import 'package:usta/data/models/filter_state.dart';
import 'package:usta/data/models/user_location.dart';
import 'package:usta/features/discovery/discovery_providers.dart';
import 'package:usta/features/location/location_controller.dart';
import 'package:usta/features/location/location_service.dart';

import '../helpers/fakes.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('filters', () {
    test(
      'picking a service sets both parts and tapping it again clears it',
      () {
        final container = ProviderContainer(overrides: testOverrides());
        addTearDown(container.dispose);
        final filters = container.read(filtersProvider.notifier);

        filters.selectService(kServices.firstWhere((s) => s.id == 'klima'));
        var state = container.read(filtersProvider);
        expect(state.mainType, 'TECHNICAL');
        expect(state.subType, 'Klima ve Kombi Servisi');

        filters.selectService(kServices.firstWhere((s) => s.id == 'boya'));
        state = container.read(filtersProvider);
        expect(state.mainType, 'CONSTRUCTION');
        expect(state.subType, 'Boyacı');

        filters.selectService(kServices.firstWhere((s) => s.id == 'boya'));
        expect(container.read(filtersProvider).subType, isNull);
        expect(container.read(filtersProvider).mainType, isNull);
      },
    );

    test(
      'searching spans every service; choosing a service ends the search',
      () {
        final container = ProviderContainer(overrides: testOverrides());
        addTearDown(container.dispose);
        final filters = container.read(filtersProvider.notifier)
          ..selectService(kServices.first)
          ..setQuery('kombi');
        var state = container.read(filtersProvider);
        expect(state.searching, isTrue);
        expect(state.mainType, isNull);
        expect(state.subType, isNull);

        filters.selectService(kServices.firstWhere((s) => s.id == 'su'));
        state = container.read(filtersProvider);
        expect(state.query, '');
        expect(state.subType, 'Su Tesisatçısı');
      },
    );

    test('a one-letter query is not a search', () {
      final container = ProviderContainer(overrides: testOverrides());
      addTearDown(container.dispose);
      container.read(filtersProvider.notifier).setQuery('k');
      final state = container.read(filtersProvider);
      expect(state.searching, isFalse);
      expect(
        ProviderQuery(filters: state).toQueryParameters(1).containsKey('q'),
        isFalse,
      );
    });

    test('clearAll resets everything but the sort order', () {
      final container = ProviderContainer(overrides: testOverrides());
      addTearDown(container.dispose);
      container.read(filtersProvider.notifier)
        ..selectService(kServices.first)
        ..setCity('Bursa')
        ..setDistance(15)
        ..setSort(SortMode.rating)
        ..clearAll();
      final state = container.read(filtersProvider);
      expect(state.hasActiveRefinements, isFalse);
      expect(state.sortMode, SortMode.rating);
    });
  });

  group('location', () {
    test(
      'startup never prompts: a denied permission just stays denied',
      () async {
        final service = FakeLocationService();
        final container = ProviderContainer(
          overrides: testOverrides(location: service),
        );
        addTearDown(container.dispose);
        container.read(locationProvider);
        await settle();
        expect(container.read(locationProvider).status, LocationStatus.denied);
        expect(container.read(providerQueryProvider).hasLocation, isFalse);
      },
    );

    test('a found location flows into the provider query', () async {
      final service = FakeLocationService(
        const LocationFound(UserLocation(lat: 41.0, lng: 29.0)),
      );
      final container = ProviderContainer(
        overrides: testOverrides(location: service),
      );
      addTearDown(container.dispose);
      container.read(locationProvider);
      await settle();
      final query = container.read(providerQueryProvider);
      expect(query.userLat, 41.0);
      expect(query.userLng, 29.0);
    });

    test('each failure mode maps to its own status', () async {
      final cases = <LocationResult, LocationStatus>{
        const LocationPermissionDeniedForever(): LocationStatus.deniedForever,
        const LocationServiceDisabled(): LocationStatus.serviceDisabled,
        const LocationUnavailable(): LocationStatus.unavailable,
      };
      for (final entry in cases.entries) {
        final container = ProviderContainer(
          overrides: testOverrides(location: FakeLocationService(entry.key)),
        );
        container.read(locationProvider);
        await settle();
        expect(container.read(locationProvider).status, entry.value);
        container.dispose();
      }
    });
  });

  group('provider list pagination', () {
    test(
      'loads the first page then appends the next without duplicates',
      () async {
        final repo = FakeUstaRepository(
          pages: [
            [fakeUsta(1), fakeUsta(2)],
            [fakeUsta(2), fakeUsta(3)],
          ],
        );
        final container = ProviderContainer(
          overrides: testOverrides(usta: repo),
        );
        addTearDown(container.dispose);
        const query = ProviderQuery(filters: FilterState());
        final sub = container.listen(ustaListProvider(query), (_, _) {});
        addTearDown(sub.close);

        expect(
          container.read(ustaListProvider(query)).status,
          ListStatus.loading,
        );
        await settle();
        var state = container.read(ustaListProvider(query));
        expect(state.status, ListStatus.data);
        expect(state.items.map((u) => u.id), ['u1', 'u2']);
        expect(state.hasMore, isTrue);

        await container.read(ustaListProvider(query).notifier).loadMore();
        state = container.read(ustaListProvider(query));
        expect(state.items.map((u) => u.id), ['u1', 'u2', 'u3']);
        expect(state.hasMore, isFalse);

        await container
            .read(ustaListProvider(query).notifier)
            .loadMore(); // no-op at the end
        expect(repo.queries.length, 2);
      },
    );

    test('a failed first page becomes an error state that can retry', () async {
      final container = ProviderContainer(
        overrides: testOverrides(
          usta: FakeUstaRepository(error: Exception('boom')),
        ),
      );
      addTearDown(container.dispose);
      const query = ProviderQuery(filters: FilterState());
      final sub = container.listen(ustaListProvider(query), (_, _) {});
      addTearDown(sub.close);
      await settle();
      final state = container.read(ustaListProvider(query));
      expect(state.status, ListStatus.error);
      expect(state.failure!.message, isNot(contains('boom')));
    });
  });
}
