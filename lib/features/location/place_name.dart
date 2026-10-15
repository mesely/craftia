import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

import '../../data/models/user_location.dart';
import 'location_controller.dart';

/// Turns coordinates into a name people recognise ("Karşıyaka, İzmir").
abstract interface class PlaceNameService {
  Future<String?> nameFor(UserLocation location);
}

class GeocodingPlaceNameService implements PlaceNameService {
  const GeocodingPlaceNameService();

  @override
  Future<String?> nameFor(UserLocation location) async {
    try {
      final marks = await Geocoding()
          .placemarkFromCoordinates(
            location.lat,
            location.lng,
            locale: const Locale('tr', 'TR'),
          )
          .timeout(const Duration(seconds: 6));
      if (marks.isEmpty) return null;
      return formatPlace(marks.first);
    } catch (_) {
      return null; // Offline or unsupported: the caller falls back to a generic label.
    }
  }

  /// "İlçe, İl" when both are known and different, otherwise whichever exists.
  static String? formatPlace(Placemark p) {
    String? clean(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();
    final province = clean(p.administrativeArea);
    final district = clean(p.subAdministrativeArea) ?? clean(p.locality);
    if (district != null && province != null && district != province) {
      return '$district, $province';
    }
    return province ?? district;
  }
}

final placeNameServiceProvider = Provider<PlaceNameService>(
  (ref) => const GeocodingPlaceNameService(),
);

/// The name of where the phone is now. Rounded to ~1 km so small GPS jitter does not re-ask.
final currentPlaceNameProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  final location = ref.watch(
    locationProvider.select((s) => s.hasLocation ? s.location : null),
  );
  if (location == null) return null;
  final rounded = UserLocation(
    lat: (location.lat * 100).roundToDouble() / 100,
    lng: (location.lng * 100).roundToDouble() / 100,
  );
  return ref.watch(placeNameServiceProvider).nameFor(rounded);
});
