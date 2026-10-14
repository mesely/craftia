import 'package:equatable/equatable.dart';

import '../../core/utils/distance.dart';

class UserLocation extends Equatable {
  const UserLocation({required this.lat, required this.lng});

  final double lat;
  final double lng;

  bool get isValid => isValidCoordinate(lat, lng);

  @override
  List<Object?> get props => [lat, lng];
}
