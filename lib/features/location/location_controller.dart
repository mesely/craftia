import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_location.dart';
import 'location_service.dart';

enum LocationStatus {
  unknown,
  loading,
  available,
  denied,
  deniedForever,
  serviceDisabled,
  unavailable,
}

class LocationState extends Equatable {
  const LocationState(this.status, [this.location]);

  final LocationStatus status;
  final UserLocation? location;

  bool get hasLocation =>
      status == LocationStatus.available && location != null;

  @override
  List<Object?> get props => [status, location];
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

class LocationController extends Notifier<LocationState> {
  @override
  LocationState build() {
    // Never block startup on GPS: quietly pick up the location only if the
    // permission is already granted.
    Future.microtask(() => _resolve(requestPermission: false));
    return const LocationState(LocationStatus.unknown);
  }

  /// Called from user actions ("Konumumu kullan"): may show the system prompt.
  Future<void> request() => _resolve(requestPermission: true);

  Future<void> openSettings() {
    final service = ref.read(locationServiceProvider);
    return state.status == LocationStatus.serviceDisabled
        ? service.openLocationSettings()
        : service.openAppSettings();
  }

  Future<void> _resolve({required bool requestPermission}) async {
    if (state.status == LocationStatus.loading) return;
    final previous = state;
    if (requestPermission) {
      state = LocationState(LocationStatus.loading, previous.location);
    }
    final result = await ref
        .read(locationServiceProvider)
        .getCurrentLocation(requestPermission: requestPermission);
    if (!ref.mounted) return;
    state = switch (result) {
      LocationFound(:final location) => LocationState(
        LocationStatus.available,
        location,
      ),
      LocationPermissionDenied() => LocationState(
        LocationStatus.denied,
        previous.location,
      ),
      LocationPermissionDeniedForever() => LocationState(
        LocationStatus.deniedForever,
        previous.location,
      ),
      LocationServiceDisabled() => LocationState(
        LocationStatus.serviceDisabled,
        previous.location,
      ),
      LocationUnavailable() => LocationState(
        previous.hasLocation
            ? LocationStatus.available
            : LocationStatus.unavailable,
        previous.location,
      ),
    };
  }
}

final locationProvider = NotifierProvider<LocationController, LocationState>(
  LocationController.new,
);
