import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/errors/app_failure.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/promotion.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';
import '../discovery/discovery_providers.dart';

final promotionCatalogProvider = FutureProvider.autoDispose<PromotionCatalog>(
  (ref) => ref.watch(promotionsRepositoryProvider).plans(),
);

/// "Öne çık": three plans, the longer the cheaper per day, and an honest summary of what it does:
/// a "Öne çıkan" label and a place at the top of the results. It does not promise a number of jobs.
class PromotionScreen extends ConsumerStatefulWidget {
  const PromotionScreen({super.key});

  @override
  ConsumerState<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends ConsumerState<PromotionScreen> {
  String? _selected;
  bool _busy = false;
  String? _error;
  PromotionReceipt? _done;

  Future<void> _buy(PromotionPlan plan) async {
    final account = ref.read(authProvider).account;
    final providerId = account?.providerId;
    if (account == null || providerId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final receipt = await ref
          .read(promotionsRepositoryProvider)
          .buy(providerId, actorId: account.id, planId: plan.id);
      ref.invalidate(ustaDetailProvider(providerId));
      if (mounted) {
        setState(() {
          _done = receipt;
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppFailure.from(e).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.ui.gutter;
    final catalog = ref.watch(promotionCatalogProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          icon: const UstaIcon(UstaIcons.arrowLeft, size: 26),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: _done != null
          ? _Done(receipt: _done!, onClose: () => context.pop())
          : catalog.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: ErrorStateView(
                  failure: AppFailure.from(e),
                  onRetry: () => ref.invalidate(promotionCatalogProvider),
                ),
              ),
              data: (c) {
                final selected = c.plans.firstWhere(
                  (p) => p.id == (_selected ?? _defaultId(c.plans)),
                  orElse: () => c.plans.first,
                );
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    0,
                    gutter,
                    AppSpacing.xxxl,
                  ),
                  children: [
                    Semantics(
                      header: true,
                      child: Text('Öne çık', style: AppTypography.display),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Aramalarda en üstte, “Öne çıkan” etiketiyle görünürsün. Süre dolunca sayfan normal sıraya döner.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    for (final p in c.plans) ...[
                      _PlanTile(
                        plan: p,
                        selected: p.id == selected.id,
                        onTap: () => setState(() => _selected = p.id),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    if (c.testMode)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.amberSoft,
                          borderRadius: AppRadius.borderMd,
                        ),
                        child: Text(
                          'Test sürümü: şu an ücret alınmıyor, öne çıkma ücretsiz başlar.',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.amberInk,
                          ),
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _error!,
                        style: AppTypography.body.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _busy ? null : () => _buy(selected),
                      child: _busy
                          ? SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : Text(
                              c.testMode
                                  ? '${selected.title} öne çık'
                                  : '${selected.title} öne çık · ${selected.priceLabel}',
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Fiyatlara KDV dahildir. Öne çıkma, belirli sayıda iş ya da müşteri garantisi vermez; yalnızca sıralamada üstte olmanı sağlar. Satın alınan süre iade edilmez, ancak yeniden satın alırsan mevcut süreye eklenir.',
                      style: AppTypography.bodySm,
                    ),
                  ],
                );
              },
            ),
    );
  }

  static String _defaultId(List<PromotionPlan> plans) =>
      (plans.firstWhere((p) => p.badge != null, orElse: () => plans.first)).id;
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PromotionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${plan.title}, ${plan.priceLabel}, ${plan.perDayLabel}'
          '${plan.badge == null ? '' : ', ${plan.badge}'}',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: selected ? AppBorders.selected : AppBorders.hairline,
        ),
        child: InkWell(
          borderRadius: AppRadius.borderMd,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                UstaIcon(
                  selected ? UstaIcons.checkCircle : UstaIcons.crown,
                  size: 28,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.title, style: AppTypography.titleSm),
                      Text(plan.perDayLabel, style: AppTypography.bodySm),
                      if (plan.badge != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            plan.badge!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(plan.priceLabel, style: AppTypography.title),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.receipt, required this.onClose});

  final PromotionReceipt receipt;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.ui.gutter,
        AppSpacing.huge,
        context.ui.gutter,
        AppSpacing.xxxl,
      ),
      children: [
        Center(
          child: UstaIcon(
            UstaIcons.checkCircle,
            size: 64,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Öne çıkıyorsun',
          style: AppTypography.display,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${formatDate(receipt.featuredUntil)} tarihine kadar aramaların en üstünde görünürsün.',
          style: AppTypography.body.copyWith(color: AppColors.inkMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(onPressed: onClose, child: const Text('Tamam')),
      ],
    );
  }
}
