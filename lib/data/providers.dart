import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import 'datasources/remote_data_source.dart';
import 'repositories/accounts_repository.dart';
import 'repositories/chat_repository.dart';
import 'repositories/complaints_repository.dart';
import 'repositories/promotions_repository.dart';
import 'repositories/requests_repository.dart';
import 'repositories/reviews_repository.dart';
import 'repositories/usta_repository.dart';

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    // Read lazily on every call, so a new sign-in is picked up without rebuilding the client.
    token: () => ref.read(sessionTokenProvider),
    onUnauthorized: () => ref.read(sessionExpiredProvider)(),
  ),
);

/// The signed session token; set by the auth controller (see `auth_controller.dart`).
final sessionTokenProvider = Provider<String?>((ref) => null);

/// Called when the server refuses the session; wired to sign-out.
final sessionExpiredProvider = Provider<void Function()>((ref) => () {});
final remoteDataSourceProvider = Provider<RemoteDataSource>(
  (ref) => RemoteDataSource(ref.watch(apiClientProvider)),
);
final ustaRepositoryProvider = Provider<UstaRepository>(
  (ref) => UstaRepository(ref.watch(remoteDataSourceProvider)),
);
final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => ReviewsRepository(ref.watch(remoteDataSourceProvider)),
);
final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepository(ref.watch(remoteDataSourceProvider)),
);
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(remoteDataSourceProvider)),
);
final complaintsRepositoryProvider = Provider<ComplaintsRepository>(
  (ref) => ComplaintsRepository(ref.watch(remoteDataSourceProvider)),
);
final promotionsRepositoryProvider = Provider<PromotionsRepository>(
  (ref) => PromotionsRepository(ref.watch(remoteDataSourceProvider)),
);
final requestsRepositoryProvider = Provider<RequestsRepository>(
  (ref) => RequestsRepository(ref.watch(remoteDataSourceProvider)),
);

/// The app has no accounts yet, so requests and reviews are tied to an anonymous id kept on the device.
final deviceIdProvider = FutureProvider<String>((ref) async {
  const key = 'device_id';
  try {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await prefs.setString(key, id);
    return id;
  } catch (_) {
    return 'guest';
  }
});
