import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/service_request.dart';
import '../../data/models/user_location.dart';
import '../../data/providers.dart';

class RequestsController extends AsyncNotifier<List<ServiceRequest>> {
  @override
  Future<List<ServiceRequest>> build() async {
    final userId = await ref.watch(deviceIdProvider.future);
    return ref.read(requestsRepositoryProvider).list(userId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Throws [AppFailure] so the form can show the message.
  Future<ServiceRequest> create({
    required String mainType,
    required String subType,
    required String city,
    required String description,
    String? providerId,
    String? contactPhone,
    UserLocation? location,
  }) async {
    final userId = await ref.read(deviceIdProvider.future);
    final created = await ref
        .read(requestsRepositoryProvider)
        .create(
          userId: userId,
          mainType: mainType,
          subType: subType,
          city: city,
          description: description,
          providerId: providerId,
          contactPhone: contactPhone,
          location: location,
        );
    if (ref.mounted) state = AsyncData([created, ...?state.value]);
    return created;
  }

  Future<void> cancel(String id) async {
    final updated = await ref.read(requestsRepositoryProvider).cancel(id);
    if (!ref.mounted) return;
    state = AsyncData([
      for (final r in state.value ?? const <ServiceRequest>[])
        r.id == id ? updated : r,
    ]);
  }
}

final requestsProvider =
    AsyncNotifierProvider<RequestsController, List<ServiceRequest>>(
      RequestsController.new,
    );
