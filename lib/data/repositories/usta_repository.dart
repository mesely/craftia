import '../../core/errors/app_failure.dart';
import '../datasources/remote_data_source.dart';
import '../models/filter_state.dart';
import '../models/paged.dart';
import '../models/provider_application.dart';
import '../models/service_price.dart';
import '../models/usta.dart';

class UstaRepository {
  UstaRepository(this._remote);

  final RemoteDataSource _remote;

  Future<Paged<Usta>> fetchPage(ProviderQuery query, int page) =>
      guarded(() async {
        final json = await _remote.getProviders(query.toQueryParameters(page));
        final items = (json['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Usta.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false);
        return Paged(
          items: items,
          total: (json['total'] as num?)?.toInt() ?? items.length,
          page: page,
          hasMore: json['hasMore'] == true,
        );
      });

  Future<Usta> getById(String id) =>
      guarded(() async => Usta.fromJson(await _remote.getProvider(id)));

  Future<Usta> apply(ProviderApplication application) => guarded(
    () async =>
        Usta.fromJson(await _remote.createProvider(application.toJson())),
  );

  /// An usta editing their own listing. Only the fields given are changed.
  Future<Usta> updateProfile(
    String id, {
    required String actorId,
    String? about,
    String? address,
    List<String>? serviceAreas,
    String? phoneNumber,
    String? businessName,
    List<ServicePrice>? priceList,
  }) => guarded(
    () async => Usta.fromJson(
      await _remote.updateProvider(id, {
        'actorId': actorId,
        'about': ?about,
        'address': ?address,
        'serviceAreas': ?serviceAreas,
        'phoneNumber': ?phoneNumber,
        'businessName': ?businessName,
        if (priceList != null)
          'priceList': [
            for (final p in priceList)
              {
                'serviceName': p.serviceName,
                'minPrice': p.minPrice,
                'maxPrice': p.maxPrice,
              },
          ],
      }),
    ),
  );

  Future<Usta> addPhoto(
    String id, {
    required String actorId,
    required String contentType,
    required String base64Data,
  }) => guarded(
    () async => Usta.fromJson(
      await _remote.addProviderPhoto(id, {
        'actorId': actorId,
        'contentType': contentType,
        'data': base64Data,
      }),
    ),
  );

  Future<Usta> setProfilePhoto(
    String id, {
    required String actorId,
    required String contentType,
    required String base64Data,
  }) => guarded(
    () async => Usta.fromJson(
      await _remote.setProviderProfilePhoto(id, {
        'actorId': actorId,
        'contentType': contentType,
        'data': base64Data,
      }),
    ),
  );

  Future<Usta> removePhoto(
    String id, {
    required String actorId,
    required String path,
  }) => guarded(
    () async => Usta.fromJson(
      await _remote.removeProviderPhoto(id, actorId: actorId, path: path),
    ),
  );
}
