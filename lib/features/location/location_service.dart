import 'package:geolocator/geolocator.dart';

import '../../data/models/user_location.dart';

sealed class LocationResult {
  const LocationResult();
}

class LocationFound extends LocationResult {
  const LocationFound(this.location);
  final UserLocation location;
}

/// Permission not granted (never asked, or denied once) — asking again is possible.
class LocationPermissionDenied extends LocationResult {
  const LocationPermissionDenied();
}

/// Denied for good — only the system settings can fix it.
class LocationPermissionDeniedForever extends LocationResult {
  const LocationPermissionDeniedForever();
}

class LocationServiceDisabled extends LocationResult {
  const LocationServiceDisabled();
}

/// Timeout, platform error, or coordinates that are not a real position.
class LocationUnavailable extends LocationResult {
  const LocationUnavailable();
}

abstract interface class LocationService {
  /// Never throws. Only prompts for permission when [requestPermission] is true.
  Future<LocationResult> getCurrentLocation({bool requestPermission = false});

  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationResult> getCurrentLocation({
    bool requestPermission = false,
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationServiceDisabled();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return const LocationPermissionDenied();
        case LocationPermission.deniedForever:
          return const LocationPermissionDeniedForever();
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final location = UserLocation(
        lat: position.latitude,
        lng: position.longitude,
      );
      return location.isValid
          ? LocationFound(location)
          : const LocationUnavailable();
    } catch (_) {
      return const LocationUnavailable();
    }
  }

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
