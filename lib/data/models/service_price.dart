import 'package:equatable/equatable.dart';

import '../../core/utils/formatters.dart';

/// One line of a provider's price list. Prices may be exact, a range, or missing.
class ServicePrice extends Equatable {
  const ServicePrice({required this.serviceName, this.minPrice, this.maxPrice});

  final String serviceName;
  final double? minPrice;
  final double? maxPrice;

  bool get hasPrice => minPrice != null || maxPrice != null;
  bool get isExact =>
      minPrice != null && maxPrice != null && minPrice == maxPrice;

  /// "1.500 – 2.000 ₺", "750 ₺", "Fiyat için arayın".
  String get priceLabel {
    final min = minPrice, max = maxPrice;
    if (min == null && max == null) return 'Fiyat için arayın';
    if (min != null && max != null) {
      if (min == max) return formatLira(min);
      return '${formatNumber(min)} – ${formatLira(max)}';
    }
    return formatLira((min ?? max)!);
  }

  factory ServicePrice.fromJson(Map<String, dynamic> json) => ServicePrice(
    serviceName: (json['serviceName'] ?? '').toString().trim(),
    minPrice: _toPrice(json['minPrice']),
    maxPrice: _toPrice(json['maxPrice']),
  );

  /// Accepts a structured list, or the legacy `{"Service": "min-max"}` map.
  static List<ServicePrice> parseList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => ServicePrice.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.serviceName.isNotEmpty)
          .toList(growable: false);
    }
    if (raw is Map) {
      return raw.entries
          .where((e) => e.key.toString().trim().isNotEmpty)
          .map((e) {
            final range = parseRange(e.value);
            return ServicePrice(
              serviceName: e.key.toString().trim(),
              minPrice: range.$1,
              maxPrice: range.$2,
            );
          })
          .toList(growable: false);
    }
    return const [];
  }

  /// Parses "100-200", "1.500 - 2.000 ₺", "850", 850 or garbage into (min, max).
  static (double?, double?) parseRange(dynamic raw) {
    if (raw is num) {
      final v = _toPrice(raw);
      return (v, v);
    }
    if (raw is! String) return (null, null);
    final parts = raw.split(RegExp(r'[-–—]'));
    final min = _toPrice(parts.first);
    final max = parts.length > 1 ? _toPrice(parts[1]) : min;
    if (min != null && max != null && max < min) return (max, min);
    return (min, max ?? min);
  }

  static double? _toPrice(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.isFinite && v > 0 ? v.toDouble() : null;
    final cleaned = v
        .toString()
        .replaceAll(RegExp(r'[^\d.,]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final n = double.tryParse(cleaned);
    return n != null && n > 0 ? n : null;
  }

  @override
  List<Object?> get props => [serviceName, minPrice, maxPrice];
}
