import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/account.dart';
import '../../data/models/service_request.dart';
import '../../data/models/user_location.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';

/// The signed-in person's requests. A customer sees what they asked for; an usta sees the inbox
/// (and still sees anything they asked for as a customer). Refreshed quietly every few seconds so
/// unread counts and status changes appear without pulling.
class RequestsController extends AsyncNotifier<List<ServiceRequest>> {
  static const _pollEvery = Duration(seconds: 15);

  @override
  Future<List<ServiceRequest>> build() async {
    final account = ref.watch(authProvider.select((s) => s.account));
    if (account == null) return const [];
    final timer = Timer.periodic(_pollEvery, (_) => _silentRefresh(account));
    ref.onDispose(timer.cancel);
    return _fetch(account);
  }

  Future<List<ServiceRequest>> _fetch(Account account) async {
    final repo = ref.read(requestsRepositoryProvider);
    final lists = await Future.wait([
      repo.list(userId: account.id),
      if (account.providerId != null) repo.list(providerId: account.providerId),
    ]);
    final byId = <String, ServiceRequest>{
      for (final list in lists)
        for (final r in list) r.id: r,
    };
    return byId.values.toList()..sort(
      (a, b) => (b.lastMessageAt ?? b.createdAt).compareTo(
        a.lastMessageAt ?? a.createdAt,
      ),
    );
  }

  Future<void> _silentRefresh(Account account) async {
    try {
      final fresh = await _fetch(account);
      if (ref.mounted) state = AsyncData(fresh);
    } catch (_) {
      // Keep what is on screen; the next tick tries again.
    }
  }

  Future<void> refresh() async {
    final account = ref.read(authProvider).account;
    if (account == null) return;
    await _silentRefresh(account);
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
    final account = ref.read(authProvider).account!;
    final created = await ref
        .read(requestsRepositoryProvider)
        .create(
          userId: account.id,
          customerName: account.name,
          mainType: mainType,
          subType: subType,
          city: city,
          description: description,
          providerId: providerId,
          contactPhone: contactPhone ?? account.phone,
          location: location,
        );
    if (ref.mounted) state = AsyncData([created, ...?state.value]);
    return created;
  }

  Future<void> changeStatus(String id, RequestStatus status) async {
    final account = ref.read(authProvider).account!;
    await ref
        .read(requestsRepositoryProvider)
        .changeStatus(id, status: status, actorId: account.id);
    await refresh();
  }
}

final requestsProvider =
    AsyncNotifierProvider<RequestsController, List<ServiceRequest>>(
      RequestsController.new,
    );

/// Unread chat messages across all requests: the bell's badge.
final unreadCountProvider = Provider<int>(
  (ref) => (ref.watch(requestsProvider).value ?? const []).fold(
    0,
    (sum, r) => sum + r.unread,
  ),
);
