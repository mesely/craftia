import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usta/data/models/filter_state.dart';
import 'package:usta/data/models/user_location.dart';
import 'package:usta/features/discovery/discovery_providers.dart';
import 'package:usta/features/location/location_controller.dart';
import 'package:usta/features/location/location_service.dart';

import '../helpers/fakes.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('filters', () {
    test('changing the category resets the sub-type', () {
      final container = ProviderContainer(overrides: testOverrides());
      addTearDown(container.dispose);
      final filters = container.read(filtersProvider.notifier);

      filters.selectSubType('Elektrikçi');
      expect(container.read(filtersProvider).subType, 'Elektrikçi');
      filters.selectCategory('LIFE');
      expect(container.read(filtersProvider).mainType, 'LIFE');
      expect(container.read(filtersProvider).subType, isNull);
    });

    test('reset keeps the category but clears refinements', () {
      final container = ProviderContainer(overrides: testOverrides());
      addTearDown(container.dispose);
      final filters = container.read(filtersProvider.notifier)
        ..selectCategory('CLIMATE')
        ..setCity('Bursa')
        ..setDistance(15);
      expect(container.read(filtersProvider).hasActiveRefinements, isTrue);
      filters.reset();
      final state = container.read(filtersProvider);
      expect(state.mainType, 'CLIMATE');
      expect(state.city, isNull);
      expect(state.distanceKm, isNull);
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
