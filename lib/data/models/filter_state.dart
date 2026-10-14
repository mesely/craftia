import 'package:equatable/equatable.dart';

enum SortMode {
  nearest('nearest', 'Yakın'),
  rating('rating', 'Puan');

  const SortMode(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

/// What the user chose in the UI. Location is added separately (see [ProviderQuery]).
class FilterState extends Equatable {
  const FilterState({
    this.mainType = 'TECHNICAL',
    this.subType,
    this.city,
    this.sortMode = SortMode.nearest,
    this.distanceKm,
    this.query = '',
  });

  /// `null` means every category (used by search).
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
  });

  final FilterState filters;
  final double? userLat;
  final double? userLng;
  final int pageSize;

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
    if (filters.query.trim().isNotEmpty) 'q': filters.query.trim(),
  };

  @override
  List<Object?> get props => [filters, userLat, userLng, pageSize];
}
