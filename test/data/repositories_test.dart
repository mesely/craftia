import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:usta/core/errors/app_failure.dart';
import 'package:usta/data/models/filter_state.dart';
import 'package:usta/data/repositories/usta_repository.dart';

import '../helpers/fakes.dart';

void main() {
  late MockRemoteDataSource remote;
  late UstaRepository repo;

  setUp(() {
    remote = MockRemoteDataSource();
    repo = UstaRepository(remote);
  });

  test(
    'maps a provider page, tolerating missing and malformed fields',
    () async {
      when(() => remote.getProviders(any())).thenAnswer(
        (_) async => {
          'items': [
            {
              'id': 'p1',
              'businessName': 'Atlas Tesisat',
              'phoneNumber': '+905321112233',
              'mainType': 'TECHNICAL',
              'subType': 'Su Tesisatçısı',
              'city': 'Ankara',
              'district': 'Çankaya',
              'address': '',
              'lat': 0,
              'lng': 0,
              'rating': 4.6,
              'reviewCount': 3,
              'isPremium': true,
              'portfolioImages': ['https://img/1.jpg', null, ''],
              'priceList': {'Gider açma': '300-700', 'Keşif': 'Arayınız'},
              'distanceKm': 2.4,
            },
            {'id': 'p2', 'businessName': 'Eksik Alanlı'},
          ],
          'total': 14,
          'hasMore': true,
        },
      );

      final page = await repo.fetchPage(
        const ProviderQuery(filters: FilterState()),
        1,
      );

      expect(page.total, 14);
      expect(page.hasMore, isTrue);
      final first = page.items.first;
      expect(first.isPremium, isTrue);
      expect(
        first.isVerified,
        isFalse,
        reason: 'premium is paid placement, not a verification',
      );
      expect(first.hasCoordinates, isFalse, reason: '(0,0) is not a location');
      expect(first.portfolioImages, ['https://img/1.jpg']);
      expect(first.priceList.length, 2);
      expect(first.startingPrice, 300);
      expect(first.distanceKm, 2.4);
      expect(page.items.last.city, '');
      expect(page.items.last.hasRating, isFalse);
    },
  );

  test('sends the filters the backend contract expects', () {
    const q = ProviderQuery(
      filters: FilterState(
        mainType: 'TECHNICAL',
        subType: 'Elektrikçi',
        city: 'İzmir',
        distanceKm: 12,
        query: ' priz ',
      ),
      userLat: 38.4,
      userLng: 27.1,
    );
    expect(q.toQueryParameters(2), {
      'page': 2,
      'limit': 10,
      'mainType': 'TECHNICAL',
      'subType': 'Elektrikçi',
      'city': 'İzmir',
      'sortMode': 'nearest',
      'distance': 12,
      'userLat': 38.4,
      'userLng': 27.1,
      'q': 'priz',
    });
  });

  test('without a location the distance limit and coordinates are omitted', () {
    const q = ProviderQuery(filters: FilterState(distanceKm: 20));
    final params = q.toQueryParameters(1);
    expect(params.containsKey('distance'), isFalse);
    expect(params.containsKey('userLat'), isFalse);
  });

  test('converts transport failures into user-presentable failures', () async {
    when(() => remote.getProviders(any())).thenThrow(AppFailure.network);
    await expectLater(
      repo.fetchPage(const ProviderQuery(filters: FilterState()), 1),
      throwsA(
        isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.network),
      ),
    );

    when(() => remote.getProviders(any()))
        .thenThrow(const FormatException('bad json'));
    await expectLater(
      repo.fetchPage(const ProviderQuery(filters: FilterState()), 1),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.message,
          'message',
          isNot(contains('bad json')),
        ),
      ),
    );
  });
}
