import 'package:equatable/equatable.dart';

import '../../core/constants/services.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/distance.dart';
import '../../core/utils/formatters.dart';
import 'service_price.dart';
import 'user_location.dart';

/// A local service provider ("usta").
class Usta extends Equatable {
  const Usta({
    required this.id,
    required this.businessName,
    required this.phoneNumber,
    required this.mainType,
    required this.subType,
    required this.city,
    required this.district,
    required this.address,
    this.lat,
    this.lng,
    this.rating = 0,
    this.reviewCount = 0,
    this.isPremium = false,
    this.featuredUntil,
    this.isVerified = false,
    this.about = '',
    this.profileImage,
    this.portfolioImages = const [],
    this.priceList = const [],
    this.serviceAreas = const [],
    this.distanceKm,
  });

  final String id;
  final String businessName;
  final String phoneNumber;
  final String mainType;
  final String subType;
  final String city;
  final String district;
  final String address;
  final double? lat;
  final double? lng;
  final double rating;
  final int reviewCount;
  final bool isPremium;

  /// When a paid "Öne çıkan" promotion ends (null when none is running).
  final DateTime? featuredUntil;
  final bool isVerified;
  final String about;
  final String? profileImage;
  final List<String> portfolioImages;
  final List<ServicePrice> priceList;

  /// Districts the usta travels to. Empty when the data does not say.
  final List<String> serviceAreas;

  /// Distance reported by the server for the user's location, if one was sent.
  final double? distanceKm;

  /// The service as people read it ("Klima & Kombi"), whatever casing the database holds.
  String get subTypeText =>
      serviceFor(mainType: mainType, subType: subType)?.label ??
      capitalizeFirst(subType);

  bool get hasRating => rating > 0;

  /// Only providers that published an address have a place to navigate to.
  /// Everyone else is shown by service area instead of a pin.
  bool get hasShopAddress => address.trim().isNotEmpty;

  bool get hasCoordinates => isValidCoordinate(lat, lng);

  /// "Kadıköy, İstanbul"
  String get locationLabel =>
      [district, city].where((s) => s.isNotEmpty).join(', ');

  /// Lowest listed price, used as the price signal on cards.
  double? get startingPrice {
    final prices = priceList
        .map((p) => p.minPrice ?? p.maxPrice)
        .whereType<double>();
    return prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b);
  }

  /// Server distance, or computed locally once the user's location is known.
  double? distanceFrom(UserLocation? user) {
    if (distanceKm != null) return distanceKm;
    if (user == null || !user.isValid || !hasCoordinates) return null;
    return haversineKm(user.lat, user.lng, lat!, lng!);
  }

  factory Usta.fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble();
    final located = isValidCoordinate(lat, lng);
    return Usta(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      businessName: (json['businessName'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      mainType: (json['mainType'] ?? '').toString(),
      subType: (json['subType'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      lat: located ? lat : null,
      lng: located ? lng : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      isPremium: json['isPremium'] == true,
      featuredUntil: DateTime.tryParse('${json['featuredUntil'] ?? ''}')
          ?.toLocal(),
      isVerified: json['isVerified'] == true,
      about: (json['about'] ?? '').toString(),
      profileImage: (json['profileImage'] as String?)?.isNotEmpty == true
          ? AppConfig.resolve(json['profileImage'] as String)
          : null,
      portfolioImages: (json['portfolioImages'] is List)
          ? (json['portfolioImages'] as List)
                .whereType<String>()
                .where((s) => s.isNotEmpty)
                .map(AppConfig.resolve)
                .toList(growable: false)
          : const [],
      priceList: ServicePrice.parseList(json['priceList']),
      serviceAreas: (json['serviceAreas'] is List)
          ? (json['serviceAreas'] as List)
                .whereType<String>()
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(growable: false)
          : const [],
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    businessName,
    phoneNumber,
    rating,
    reviewCount,
    distanceKm,
    isPremium,
    featuredUntil,
    profileImage,
    about,
    priceList,
    portfolioImages,
    serviceAreas,
  ];
}
