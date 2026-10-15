import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/usta.dart';
import '../auth/auth_controller.dart';
import '../discovery/discovery_providers.dart';
import '../profile/profile_edit_screen.dart';
import '../provider/widgets/usta_parts.dart';
import 'profile_completeness.dart';

/// "Sayfam": the usta's listing, editable in place: photo, introduction, services and prices,
/// work photos and where they work. A short header shows how complete the page is.
class ProviderPageScreen extends ConsumerWidget {
  const ProviderPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerId = ref.watch(
      authProvider.select((s) => s.account?.providerId),
    );
    if (providerId == null) {
      return Center(
        child: Text('Henüz bir usta sayfan yok.', style: AppTypography.body),
      );
    }
    return ref
        .watch(ustaDetailProvider(providerId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: ErrorStateView(
              failure: AppFailure.from(e),
              onRetry: () => ref.invalidate(ustaDetailProvider(providerId)),
            ),
          ),
          data: (usta) => ProfileEditForm(
            // A new key per load keeps the form in step with what the server returned.
            key: ValueKey(
              '${usta.id}-${usta.profileImage}-${usta.portfolioImages.length}',
            ),
            usta: usta,
            embedded: true,
            header: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Semantics(
                  header: true,
                  child: Text('Sayfam', style: AppTypography.display),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Summary(usta: usta),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.usta});

  final Usta usta;

  @override
  Widget build(BuildContext context) {
    final c = ProfileCompleteness.of(usta);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UstaAvatar(usta: usta, size: 64),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usta.businessName,
                      style: AppTypography.titleSm,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(usta.subTypeText, style: AppTypography.bodySm),
                    if (usta.isPremium)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: FeaturedLabel(),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  c.complete
                      ? 'Sayfan tamam.'
                      : 'Sayfan %${(c.fraction * 100).round()} tamam.',
                  style: AppTypography.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.borderSm,
            child: LinearProgressIndicator(
              value: c.fraction,
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
              color: c.complete ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/usta/${usta.id}', extra: usta),
              child: const Text('Müşteri gözüyle gör'),
            ),
          ),
        ],
      ),
    );
  }
}
