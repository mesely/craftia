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

  Future<List<dynamic>> getCategories() async =>
      (await _api.get('/categories')) as List<dynamic>;

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

  Future<List<dynamic>> getServiceRequests(String userId) async =>
      (await _api.get('/service-requests', query: {'userId': userId}))
          as List<dynamic>;

  Future<Map<String, dynamic>> cancelServiceRequest(String id) async => _asMap(
    await _api.patch(
      '/service-requests/$id/status',
      body: {'status': 'CANCELLED'},
    ),
  );

  Map<String, dynamic> _asMap(dynamic data) =>
      Map<String, dynamic>.from(data as Map);
}
