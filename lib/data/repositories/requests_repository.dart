import '../../core/errors/app_failure.dart';
import '../datasources/remote_data_source.dart';
import '../models/service_request.dart';
import '../models/user_location.dart';

class RequestsRepository {
  RequestsRepository(this._remote);

  final RemoteDataSource _remote;

  Future<ServiceRequest> create({
    required String userId,
    required String mainType,
    required String subType,
    required String city,
    required String description,
    String? providerId,
    String? contactPhone,
    UserLocation? location,
  }) async {
    try {
      return ServiceRequest.fromJson(
        await _remote.createServiceRequest({
          'userId': userId,
          'mainType': mainType,
          if (subType.isNotEmpty) 'subType': subType,
          'city': city,
          'description': description,
          'providerId': ?providerId,
          if (contactPhone != null && contactPhone.isNotEmpty)
            'contactPhone': contactPhone,
          if (location != null && location.isValid) 'lat': location.lat,
          if (location != null && location.isValid) 'lng': location.lng,
        }),
      );
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw AppFailure.unknown;
    }
  }

  Future<List<ServiceRequest>> list(String userId) async {
    try {
      return (await _remote.getServiceRequests(userId))
          .whereType<Map>()
          .map((e) => ServiceRequest.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw AppFailure.unknown;
    }
  }

  Future<ServiceRequest> cancel(String id) async {
    try {
      return ServiceRequest.fromJson(await _remote.cancelServiceRequest(id));
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw AppFailure.unknown;
    }
  }
}
