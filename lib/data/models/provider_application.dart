import 'service_price.dart';

/// Payload of "Hizmet Veren Ol". Premium/verified/rating are never set by the client.
class ProviderApplication {
  const ProviderApplication({
    required this.businessName,
    required this.phoneNumber,
    required this.mainType,
    required this.subType,
    required this.city,
    required this.district,
    this.address = '',
    this.about = '',
    this.priceList = const [],
    this.serviceAreas = const [],
    this.demo = false,
    this.lat,
    this.lng,
  });

  final String businessName;
  final String phoneNumber;
  final String mainType;
  final String subType;
  final String city;
  final String district;
  final String address;
  final String about;
  final List<ServicePrice> priceList;

  /// Districts served by an usta who travels to customers (no shop address).
  final List<String> serviceAreas;

  /// Created through the mock sign-in; flagged so the record is easy to clean up.
  final bool demo;

  /// Where the shop (or the usta's phone) is, when the device could tell.
  final double? lat;
  final double? lng;

  Map<String, dynamic> toJson() => {
    'businessName': businessName,
    'phoneNumber': phoneNumber,
    'mainType': mainType,
    'subType': subType,
    'city': city,
    'district': district,
    if (address.isNotEmpty) 'address': address,
    if (about.isNotEmpty) 'about': about,
    if (serviceAreas.isNotEmpty) 'serviceAreas': serviceAreas,
    if (demo) 'demo': true,
    if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
    'priceList': [
      for (final p in priceList)
        {
          'serviceName': p.serviceName,
          'minPrice': p.minPrice,
          'maxPrice': p.maxPrice,
        },
    ],
  };
}

/// The original "max price ceiling" rule: x2 up to 2.000 ₺, x1.5 up to 10.000 ₺, x1.3 above.
double maxAllowedPrice(double min) {
  if (min <= 2000) return min * 2;
  if (min <= 10000) return min * 1.5;
  return min * 1.3;
}

/// Returns a Turkish error message, or `null` when the range is acceptable.
String? validatePriceRange(double? min, double? max) {
  if (min == null || max == null || min <= 0 || max <= 0) {
    return 'Min ve maks fiyatı gir.';
  }
  if (max < min) return 'Maks fiyat, min fiyattan küçük olamaz.';
  final ceiling = maxAllowedPrice(min);
  if (max > ceiling) {
    return 'Bu fiyat için en fazla ${ceiling.round()} ₺ girebilirsin.';
  }
  return null;
}
