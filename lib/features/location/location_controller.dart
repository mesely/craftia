import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // Never block startup on GPS. The very first time the home page opens we ask once
    // (the system dialog explains itself); afterwards we only pick the location up quietly
    // when the permission is already granted.
    Future.microtask(_startup);
    return const LocationState(LocationStatus.unknown);
  }

  static const _promptedKey = 'location_prompted';

  Future<void> _startup() async {
    var firstTime = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      firstTime = !(prefs.getBool(_promptedKey) ?? false);
      if (firstTime) await prefs.setBool(_promptedKey, true);
    } catch (_) {
      // No storage: behave like a returning visitor (never nag).
    }
    if (ref.mounted) await _resolve(requestPermission: firstTime);
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
