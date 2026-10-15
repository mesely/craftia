import '../../core/errors/app_failure.dart';
import '../datasources/remote_data_source.dart';
import '../models/service_request.dart';
import '../models/user_location.dart';

class RequestsRepository {
  RequestsRepository(this._remote);

  final RemoteDataSource _remote;

  Future<ServiceRequest> create({
    required String userId,
    required String customerName,
    required String mainType,
    required String subType,
    required String city,
    required String description,
    String? providerId,
    String? contactPhone,
    UserLocation? location,
  }) => guarded(
    () async => ServiceRequest.fromJson(
      await _remote.createServiceRequest({
        'userId': userId,
        'customerName': customerName,
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
    ),
  );

  /// A customer's own requests ([userId]) or an usta's inbox ([providerId]).
  Future<List<ServiceRequest>> list({String? userId, String? providerId}) =>
      guarded(
        () async =>
            (await _remote.getServiceRequests(
                  userId: userId,
                  providerId: providerId,
                ))
                .whereType<Map>()
                .map(
                  (e) => ServiceRequest.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false),
      );

  Future<ServiceRequest> changeStatus(
    String id, {
    required RequestStatus status,
    required String actorId,
  }) => guarded(
    () async => ServiceRequest.fromJson(
      await _remote.changeRequestStatus(
        id,
        status: status.apiValue,
        actorId: actorId,
      ),
    ),
  );
}
