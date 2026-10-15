import '../../core/errors/app_failure.dart';
import '../datasources/remote_data_source.dart';
import '../models/promotion.dart';

class PromotionsRepository {
  PromotionsRepository(this._remote);

  final RemoteDataSource _remote;

  Future<PromotionCatalog> plans() => guarded(() async {
    final json = await _remote.getPromotionPlans();
    return PromotionCatalog(
      testMode: json['testMode'] == true,
      plans: (json['plans'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => PromotionPlan.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  });

  Future<PromotionReceipt> buy(
    String providerId, {
    required String actorId,
    required String planId,
  }) => guarded(() async {
    final json = await _remote.buyPromotion(providerId, {
      'actorId': actorId,
      'planId': planId,
    });
    return PromotionReceipt(
      featuredUntil:
          DateTime.tryParse('${json['featuredUntil']}')?.toLocal() ??
          DateTime.now(),
      testMode: json['testMode'] == true,
    );
  });
}
