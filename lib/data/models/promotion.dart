import 'package:equatable/equatable.dart';

import '../../core/utils/formatters.dart';

/// One way to buy "Öne çıkan" placement for a number of days.
class PromotionPlan extends Equatable {
  const PromotionPlan({
    required this.id,
    required this.days,
    required this.priceTry,
    this.badge,
  });

  final String id;
  final int days;
  final int priceTry;
  final String? badge;

  double get perDay => priceTry / days;

  String get title => switch (days) {
    7 => '1 hafta',
    30 => '1 ay',
    90 => '3 ay',
    _ => '$days gün',
  };

  /// "99 ₺" and "günlüğü 3,30 ₺"
  String get priceLabel => formatLira(priceTry);
  String get perDayLabel =>
      'günlüğü ${perDay.toStringAsFixed(2).replaceAll('.', ',')} ₺';

  factory PromotionPlan.fromJson(Map<String, dynamic> json) => PromotionPlan(
    id: (json['id'] ?? '').toString(),
    days: (json['days'] as num?)?.toInt() ?? 0,
    priceTry: (json['priceTry'] as num?)?.toInt() ?? 0,
    badge: (json['badge'] as String?)?.isNotEmpty == true
        ? json['badge'] as String
        : null,
  );

  @override
  List<Object?> get props => [id, days, priceTry, badge];
}

class PromotionCatalog {
  const PromotionCatalog({required this.plans, required this.testMode});

  final List<PromotionPlan> plans;

  /// The server is not charging yet; the app says so instead of pretending.
  final bool testMode;
}

class PromotionReceipt {
  const PromotionReceipt({required this.featuredUntil, required this.testMode});

  final DateTime featuredUntil;
  final bool testMode;
}
