import '../../core/network/api_client.dart';

/// Raw REST access. Returns decoded JSON; mapping to models happens in repositories.
class RemoteDataSource {
  RemoteDataSource(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> getProviders(Map<String, dynamic> query) async =>
      _asMap(await _api.get('/providers', query: query));

  Future<Map<String, dynamic>> getProvider(String id) async =>
      _asMap(await _api.get('/providers/$id'));

  Future<Map<String, dynamic>> createProvider(
    Map<String, dynamic> body,
  ) async => _asMap(await _api.post('/providers', body: body));

  Future<Map<String, dynamic>> updateProvider(
    String id,
    Map<String, dynamic> body,
  ) async => _asMap(await _api.patch('/providers/$id', body: body));

  Future<Map<String, dynamic>> addProviderPhoto(
    String id,
    Map<String, dynamic> body,
  ) async => _asMap(await _api.post('/providers/$id/photos', body: body));

  Future<Map<String, dynamic>> removeProviderPhoto(
    String id, {
    required String actorId,
    required String path,
  }) async => _asMap(
    await _api.delete(
      '/providers/$id/photos',
      query: {'actorId': actorId, 'path': path},
    ),
  );

  Future<Map<String, dynamic>> getReviews(
    String providerId, {
    required int page,
    required int limit,
  }) async => _asMap(
    await _api.get(
      '/providers/$providerId/reviews',
      query: {'page': page, 'limit': limit},
    ),
  );

  Future<Map<String, dynamic>> createReview(
    String providerId,
    Map<String, dynamic> body,
  ) async =>
      _asMap(await _api.post('/providers/$providerId/reviews', body: body));

  Future<Map<String, dynamic>> createServiceRequest(
    Map<String, dynamic> body,
  ) async => _asMap(await _api.post('/service-requests', body: body));

  Future<List<dynamic>> getServiceRequests({
    String? userId,
    String? providerId,
  }) async => (await _api.get(
    '/service-requests',
    query: {'userId': ?userId, 'providerId': ?providerId},
  )) as List<dynamic>;

  Future<Map<String, dynamic>> changeRequestStatus(
    String id, {
    required String status,
    required String actorId,
  }) async => _asMap(
    await _api.patch(
      '/service-requests/$id/status',
      body: {'status': status, 'actorId': actorId},
    ),
  );

  // ── accounts / privacy ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> upsertAccount(Map<String, dynamic> body) async =>
      _asMap(await _api.put('/accounts', body: body));

  Future<Map<String, dynamic>> exportData(String accountId) async => _asMap(
    await _api.get('/privacy/export', query: {'accountId': accountId}),
  );

  Future<Map<String, dynamic>> deleteAccount(String accountId) async => _asMap(
    await _api.delete('/privacy/account', query: {'accountId': accountId}),
  );

  // ── complaints ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createComplaint(
    Map<String, dynamic> body,
  ) async => _asMap(await _api.post('/complaints', body: body));

  // ── chat ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getConversation(
    String id,
    String viewerId,
  ) async => _asMap(
    await _api.get('/conversations/$id', query: {'viewerId': viewerId}),
  );

  Future<List<dynamic>> getMessages(
    String id,
    String viewerId, {
    String? after,
  }) async => (await _api.get(
    '/conversations/$id/messages',
    query: {'viewerId': viewerId, 'after': ?after},
  )) as List<dynamic>;

  Future<Map<String, dynamic>> sendMessage(
    String id,
    Map<String, dynamic> body,
  ) async => _asMap(await _api.post('/conversations/$id/messages', body: body));

  Future<Map<String, dynamic>> editMessage(
    String id,
    Map<String, dynamic> body,
  ) async => _asMap(await _api.patch('/messages/$id', body: body));

  Future<Map<String, dynamic>> deleteMessage(
    String id,
    String senderId,
  ) async =>
      _asMap(await _api.delete('/messages/$id', query: {'senderId': senderId}));

  Future<void> markRead(String id, String viewerId) async {
    await _api.post('/conversations/$id/read', body: {'viewerId': viewerId});
  }

  Future<Map<String, dynamic>> uploadAttachment(
    String conversationId,
    Map<String, dynamic> body,
  ) async => _asMap(
    await _api.post('/conversations/$conversationId/attachments', body: body),
  );

  Map<String, dynamic> _asMap(dynamic data) =>
      Map<String, dynamic>.from(data as Map);
}
