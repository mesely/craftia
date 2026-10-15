import 'package:equatable/equatable.dart';

enum SortMode {
  nearest('nearest', 'En yakın', 'En yakın'),
  rating('rating', 'En yüksek puan', 'Puana göre');

  const SortMode(this.apiValue, this.label, this.shortLabel);
  final String apiValue;
  final String label;

  /// Fits inside the sort button on a small phone.
  final String shortLabel;
}

/// What the user chose in the UI. Location is added separately (see [ProviderQuery]).
class FilterState extends Equatable {
  const FilterState({
    this.mainType,
    this.subType,
    this.city,
    this.sortMode = SortMode.nearest,
    this.distanceKm,
    this.query = '',
  });

  /// `null` means every category.
  final String? mainType;
  final String? subType;
  final String? city;
  final SortMode sortMode;
  final double? distanceKm;
  final String query;

  FilterState copyWith({
    String? mainType,
    bool clearMainType = false,
    String? subType,
    bool clearSubType = false,
    String? city,
    bool clearCity = false,
    SortMode? sortMode,
    double? distanceKm,
    bool clearDistance = false,
    String? query,
  }) => FilterState(
    mainType: clearMainType ? null : (mainType ?? this.mainType),
    subType: clearSubType ? null : (subType ?? this.subType),
    city: clearCity ? null : (city ?? this.city),
    sortMode: sortMode ?? this.sortMode,
    distanceKm: clearDistance ? null : (distanceKm ?? this.distanceKm),
    query: query ?? this.query,
  );

  /// Search needs two characters to be meaningful; shorter text is ignored.
  bool get searching => query.trim().length >= 2;

  /// Anything narrowing the list: a service, a city or a distance.
  bool get hasActiveRefinements =>
      subType != null || city != null || distanceKm != null;

  @override
  List<Object?> get props => [
    mainType,
    subType,
    city,
    sortMode,
    distanceKm,
    query,
  ];
}

/// Filters + coordinates: the exact key of one provider list.
class ProviderQuery extends Equatable {
  const ProviderQuery({
    required this.filters,
    this.userLat,
    this.userLng,
    this.pageSize = 10,
    this.excludeId,
  });

  final FilterState filters;
  final double? userLat;
  final double? userLng;
  final int pageSize;

  /// An usta's own listing, which they never see among the results.
  final String? excludeId;

  bool get hasLocation => userLat != null && userLng != null;

  Map<String, dynamic> toQueryParameters(int page) => {
    'page': page,
    'limit': pageSize,
    if (filters.mainType != null) 'mainType': filters.mainType,
    if (filters.subType != null) 'subType': filters.subType,
    if (filters.city != null) 'city': filters.city,
    'sortMode': filters.sortMode.apiValue,
    if (filters.distanceKm != null && hasLocation)
      'distance': filters.distanceKm!.round(),
    if (hasLocation) 'userLat': userLat,
    if (hasLocation) 'userLng': userLng,
    if (filters.searching) 'q': filters.query.trim(),
    if (excludeId != null) 'excludeId': excludeId,
  };

  @override
  List<Object?> get props => [filters, userLat, userLng, pageSize, excludeId];
}
