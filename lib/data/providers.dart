import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import 'datasources/remote_data_source.dart';
import 'repositories/requests_repository.dart';
import 'repositories/reviews_repository.dart';
import 'repositories/usta_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final remoteDataSourceProvider = Provider<RemoteDataSource>(
  (ref) => RemoteDataSource(ref.watch(apiClientProvider)),
);
final ustaRepositoryProvider = Provider<UstaRepository>(
  (ref) => UstaRepository(ref.watch(remoteDataSourceProvider)),
);
final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => ReviewsRepository(ref.watch(remoteDataSourceProvider)),
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
