import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mocktail/mocktail.dart';
import 'package:usta/data/datasources/remote_data_source.dart';
import 'package:usta/data/models/account.dart';
import 'package:usta/data/models/filter_state.dart';
import 'package:usta/data/models/paged.dart';
import 'package:usta/data/models/review.dart';
import 'package:usta/data/models/service_price.dart';
import 'package:usta/data/models/service_request.dart';
import 'package:usta/data/models/user_location.dart';
import 'package:usta/data/models/usta.dart';
import 'package:usta/data/providers.dart';
import 'package:usta/data/repositories/requests_repository.dart';
import 'package:usta/data/repositories/reviews_repository.dart';
import 'package:usta/data/repositories/usta_repository.dart';
import 'package:usta/features/auth/auth_controller.dart';
import 'package:usta/features/auth/auth_store.dart';
import 'package:usta/features/location/location_controller.dart';
import 'package:usta/features/location/place_name.dart';
import 'package:usta/features/location/location_service.dart';

class MockRemoteDataSource extends Mock implements RemoteDataSource {}

/// No images: widget tests must not touch the network or image cache plugins.
Usta fakeUsta(
  int n, {
  bool premium = false,
  double rating = 4.5,
  bool withPrices = true,
}) => Usta(
  id: 'u$n',
  businessName: 'Yıldız Elektrik $n',
  phoneNumber: '+90532000000$n',
  mainType: 'TECHNICAL',
  subType: 'Elektrikçi',
  city: 'İstanbul',
  district: 'Kadıköy',
  address: 'Moda Cd. No:$n, Kadıköy/İstanbul',
  lat: 40.99,
  lng: 29.03,
  rating: rating,
  reviewCount: 12,
  isPremium: premium,
  isVerified: premium,
  about: 'Yıllardır bölgede hizmet veriyoruz.',
  priceList: withPrices
      ? const [
          ServicePrice(
            serviceName: 'Priz değişimi',
            minPrice: 150,
            maxPrice: 300,
          ),
          ServicePrice(serviceName: 'Keşif', minPrice: null, maxPrice: null),
        ]
      : const [],
);

class FakeUstaRepository extends UstaRepository {
  FakeUstaRepository({this.pages = const [], this.error, this.gate})
    : super(MockRemoteDataSource());

  /// Each inner list is one page.
  final List<List<Usta>> pages;
  final Object? error;

  /// When set, `fetchPage` waits for it (to observe the loading state).
  final Completer<void>? gate;
  final List<ProviderQuery> queries = [];

  @override
  Future<Paged<Usta>> fetchPage(ProviderQuery query, int page) async {
    queries.add(query);
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    final items = page <= pages.length ? pages[page - 1] : <Usta>[];
    return Paged(
      items: items,
      total: pages.expand((p) => p).length,
      page: page,
      hasMore: page < pages.length,
    );
  }

  @override
  Future<Usta> getById(String id) async =>
      pages.expand((p) => p).firstWhere((u) => u.id == id);
}

class FakeReviewsRepository extends ReviewsRepository {
  FakeReviewsRepository() : super(MockRemoteDataSource());

  @override
  Future<ReviewsPage> fetchPage(
    String providerId,
    int page, {
    int limit = 5,
  }) async => ReviewsPage(
    items: [
      Review(
        id: 'r1',
        providerId: providerId,
        authorName: 'Ayşe K.',
        rating: 5,
        comment: 'Çok memnun kaldım.',
        createdAt: DateTime(2026, 9, 1),
      ),
    ],
    total: 1,
    page: 1,
    hasMore: false,
    averageRating: 5,
  );
}

class FakeRequestsRepository extends RequestsRepository {
  FakeRequestsRepository() : super(MockRemoteDataSource());

  @override
  Future<List<ServiceRequest>> list({
    String? userId,
    String? providerId,
  }) async => const [];
}

class FakeLocationService implements LocationService {
  FakeLocationService([this.result = const LocationPermissionDenied()]);

  LocationResult result;
  int calls = 0;

  @override
  Future<LocationResult> getCurrentLocation({
    bool requestPermission = false,
  }) async {
    calls++;
    return result;
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

class FakePlaceNameService implements PlaceNameService {
  @override
  Future<String?> nameFor(UserLocation location) async => 'Karşıyaka, İzmir';
}

const testCustomer = Account(
  id: 'test-customer-1',
  role: AccountRole.customer,
  name: 'Ayşe Yılmaz',
  phone: '05321234567',
  email: 'ayse@example.com',
);

const testUsta = Account(
  id: 'test-usta-1',
  role: AccountRole.provider,
  name: 'Ali Usta',
  phone: '05329998877',
  email: 'ali@example.com',
  providerId: 'u1',
);

/// [account] null = a guest who has already seen the welcome pages.
List<Override> testOverrides({
  UstaRepository? usta,
  FakeLocationService? location,
  Account? account,
  bool onboardingSeen = true,
}) => [
  ustaRepositoryProvider.overrideWithValue(
    usta ??
        FakeUstaRepository(
          pages: [
            [fakeUsta(1)],
          ],
        ),
  ),
  reviewsRepositoryProvider.overrideWithValue(FakeReviewsRepository()),
  requestsRepositoryProvider.overrideWithValue(FakeRequestsRepository()),
  locationServiceProvider.overrideWithValue(location ?? FakeLocationService()),
  placeNameServiceProvider.overrideWithValue(FakePlaceNameService()),
  initialAuthProvider.overrideWithValue(
    AuthSnapshot(account: account, onboardingSeen: onboardingSeen),
  ),
];
