import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mocktail/mocktail.dart';
import 'package:usta/data/datasources/remote_data_source.dart';
import 'package:usta/core/errors/app_failure.dart';
import 'package:usta/data/models/account.dart';
import 'package:usta/data/models/auth_methods.dart';
import 'package:usta/data/models/session.dart';
import 'package:usta/features/auth/federated_sign_in.dart';
import 'package:usta/data/repositories/accounts_repository.dart';
import 'package:usta/data/models/filter_state.dart';
import 'package:usta/data/models/paged.dart';
import 'package:usta/data/models/review.dart';
import 'package:usta/data/models/service_price.dart';
import 'package:usta/data/models/service_request.dart';
import 'package:usta/data/models/user_location.dart';
import 'package:usta/data/models/usta.dart';
import 'package:usta/data/providers.dart';
import 'package:usta/data/models/promotion.dart';
import 'package:usta/data/models/provider_application.dart';
import 'package:usta/data/repositories/promotions_repository.dart';
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
  final List<ProviderApplication> applications = [];

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
  Future<Usta> apply(ProviderApplication application) async {
    applications.add(application);
    return fakeUsta(9);
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

/// Behaves like the server's account rules, in memory: unique e-mail and phone, password check.
class FakeAccountsRepository extends AccountsRepository {
  FakeAccountsRepository() : super(MockRemoteDataSource());

  final accounts = <Account>[];
  final _passwords = <String, String>{};
  final applications = <ProviderApplication>[];
  String? deleted;
  var _next = 0;

  /// Which Firebase methods the "server" reports as switched on.
  Set<SignInMethod> enabledMethods = {};
  FederatedOutcome? nextOutcome;
  final firebaseCalls = <String>[];

  @override
  Future<AuthMethods> methods() async => AuthMethods(enabled: enabledMethods);

  @override
  Future<FederatedOutcome> firebaseLogin(
    String idToken, {
    String? role,
    String? name,
    String? phone,
  }) async {
    firebaseCalls.add('$idToken|${role ?? ''}|${name ?? ''}');
    if (role != null) {
      return FederatedOutcome.session(
        _create(
          AccountRole.customer,
          name ?? 'Yeni',
          phone ?? '',
          '$idToken@x.test',
          'x',
        ),
      );
    }
    return nextOutcome ??
        FederatedOutcome.session(
          _create(
            AccountRole.customer,
            'Google Kişi',
            '0555$idToken',
            '$idToken@x.test',
            'x',
          ),
        );
  }

  static String _norm(String v) =>
      v.trim().toLowerCase().replaceAll(RegExp(r'\s'), '');

  Session _create(
    AccountRole role,
    String name,
    String phone,
    String email,
    String password, {
    String? providerId,
  }) {
    final dup = accounts.any(
      (a) => _norm(a.email) == _norm(email) || _norm(a.phone) == _norm(phone),
    );
    if (dup) {
      throw const AppFailure(
        FailureKind.invalid,
        'Bu e-posta ile zaten bir hesap var. Giriş yapabilirsin.',
      );
    }
    final account = Account(
      id: 'acc-${_next++}',
      role: role,
      name: name,
      phone: phone,
      email: email.trim().toLowerCase(),
      providerId: providerId,
    );
    accounts.add(account);
    _passwords[account.id] = password;
    return Session(account: account, token: 'token-${account.id}');
  }

  @override
  Future<Session> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async => _create(AccountRole.customer, name, phone, email, password);

  @override
  Future<Session> registerProvider({
    required String name,
    required String phone,
    required String email,
    required String password,
    required ProviderApplication application,
  }) async {
    applications.add(application);
    return _create(
      AccountRole.provider,
      name,
      phone,
      email,
      password,
      providerId: 'listing-${applications.length}',
    );
  }

  @override
  Future<Session> login(String identifier, String password) async {
    final id = _norm(identifier);
    final match = accounts.where(
      (a) => _norm(a.email) == id || _norm(a.phone) == id,
    );
    if (match.isEmpty) {
      throw const AppFailure(
        FailureKind.invalid,
        'Bu bilgilerle kayıtlı hesap bulamadık. Önce kayıt olabilirsin.',
      );
    }
    final a = match.first;
    if (_passwords[a.id] != password) {
      throw const AppFailure(
        FailureKind.invalid,
        'Şifre yanlış. Lütfen tekrar dene.',
      );
    }
    return Session(account: a, token: 'token-${a.id}');
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    deleted = accountId;
    accounts.removeWhere((a) => a.id == accountId);
  }
}

class FakeFederatedSignIn implements FederatedSignIn {
  FakeFederatedSignIn(this.token);

  final String? token;
  final asked = <SignInMethod>[];

  @override
  Future<String?> idToken(SignInMethod method) async {
    asked.add(method);
    return token;
  }
}

class FakePromotionsRepository extends PromotionsRepository {
  FakePromotionsRepository() : super(MockRemoteDataSource());

  final bought = <String>[];

  @override
  Future<PromotionCatalog> plans() async => const PromotionCatalog(
    testMode: true,
    plans: [
      PromotionPlan(id: 'week', days: 7, priceTry: 99),
      PromotionPlan(
        id: 'month',
        days: 30,
        priceTry: 249,
        badge: 'En çok tercih edilen',
      ),
      PromotionPlan(id: 'quarter', days: 90, priceTry: 599),
    ],
  );

  @override
  Future<PromotionReceipt> buy(
    String providerId, {
    required String actorId,
    required String planId,
  }) async {
    bought.add(planId);
    return PromotionReceipt(
      featuredUntil: DateTime.now().add(const Duration(days: 30)),
      testMode: true,
    );
  }
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

  @override
  Future<PlaceDetails?> detailsFor(UserLocation location) async =>
      const PlaceDetails(
        city: 'İzmir',
        district: 'Karşıyaka',
        address: 'Bostanlı Mah. Cemal Gürsel Cd. No:12',
      );
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
  FakePromotionsRepository? promotions,
  FakeAccountsRepository? accountsRepo,
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
  accountsRepositoryProvider.overrideWithValue(
    accountsRepo ?? FakeAccountsRepository(),
  ),
  promotionsRepositoryProvider.overrideWithValue(
    promotions ?? FakePromotionsRepository(),
  ),
  locationServiceProvider.overrideWithValue(location ?? FakeLocationService()),
  placeNameServiceProvider.overrideWithValue(FakePlaceNameService()),
  initialAuthProvider.overrideWithValue(
    AuthSnapshot(account: account, onboardingSeen: onboardingSeen),
  ),
];
