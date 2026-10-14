import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_location.dart';
import '../../data/models/usta.dart';
import 'schematic_map_surface.dart';

/// A provider that can be placed on the map (only providers with a real position).
class MapPin {
  const MapPin({
    required this.id,
    required this.lat,
    required this.lng,
    required this.label,
    this.isFeatured = false,
  });

  final String id;
  final double lat;
  final double lng;
  final String label;
  final bool isFeatured;

  static MapPin? fromUsta(Usta usta) {
    if (!usta.hasCoordinates) {
      return null;
    }
    return MapPin(
      id: usta.id,
      lat: usta.lat!,
      lng: usta.lng!,
      label: usta.businessName,
      isFeatured: usta.isPremium,
    );
  }
}

/// Everything a map implementation needs. Keep this contract free of any SDK types.
class MapSurfaceData {
  const MapSurfaceData({
    required this.pins,
    required this.onPinTap,
    this.user,
    this.selectedId,
  });

  final List<MapPin> pins;
  final UserLocation? user;
  final String? selectedId;

  /// `null` means the empty map was tapped (clear the selection).
  final ValueChanged<String?> onPinTap;
}

/// Swap point for a real map SDK (Google Maps, Mapbox, MapLibre…).
///
/// To integrate one: implement this interface with the SDK's widget, render
/// [MapSurfaceData.pins] as markers, [MapSurfaceData.user] as the user dot, and
/// call [MapSurfaceData.onPinTap] on marker / map taps. Then return it from
/// [mapSurfaceBuilderProvider]. Nothing else in the app changes.
abstract interface class MapSurfaceBuilder {
  Widget build(BuildContext context, MapSurfaceData data);
}

final mapSurfaceBuilderProvider = Provider<MapSurfaceBuilder>(
  (ref) => const SchematicMapSurfaceBuilder(),
);
