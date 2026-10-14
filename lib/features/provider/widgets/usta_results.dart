import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/illustrations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/filter_state.dart';
import '../../../data/models/user_location.dart';
import '../../discovery/discovery_providers.dart';
import '../../location/location_controller.dart';
import 'usta_card.dart';

/// Loads the next page when the user scrolls near the end of [child]'s list.
/// Lives outside `itemBuilder` so building rows never triggers side effects.
class LoadMoreOnScroll extends ConsumerWidget {
  const LoadMoreOnScroll({super.key, required this.query, required this.child});

  final ProviderQuery query;
  final Widget child;

  static const _prefetchExtent = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.depth == 0 &&
            n is! ScrollStartNotification &&
            n.metrics.extentAfter < _prefetchExtent) {
          ref.read(ustaListProvider(query).notifier).loadMore();
        }
        return false;
      },
      child: child,
    );
  }
}

/// Sliver that renders one paginated provider list in all of its states.
class UstaResultsSliver extends ConsumerWidget {
  const UstaResultsSliver({
    super.key,
    required this.query,
    this.onClearFilters,
    this.emptyTitle,
    this.emptyMessage,
  });

  final ProviderQuery query;
  final VoidCallback? onClearFilters;
  final String? emptyTitle;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ustaListProvider(query));
    final controller = ref.read(ustaListProvider(query).notifier);
    final location = ref.watch(
      locationProvider.select((s) => s.hasLocation ? s.location : null),
    );
    return _build(context, state, controller, location);
  }

  Widget _build(
    BuildContext context,
    UstaListState state,
    UstaListController controller,
    UserLocation? location,
  ) {
    switch (state.status) {
      case ListStatus.loading:
        return const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          sliver: SliverToBoxAdapter(child: UstaListSkeleton()),
        );
      case ListStatus.error:
        return SliverToBoxAdapter(
          child: ErrorStateView(
            failure: state.failure!,
            onRetry: controller.refresh,
          ),
        );
      case ListStatus.data:
        if (state.items.isEmpty) {
          return SliverToBoxAdapter(
            child: StateView(
              illustration: Illustrations.emptySearch,
              title: emptyTitle ?? 'Bu filtrelere uygun usta bulamadık.',
              message:
                  emptyMessage ??
                  'Filtreleri biraz gevşetip tekrar deneyebilirsin.',
              actionLabel: onClearFilters != null ? 'Filtreleri temizle' : null,
              onAction: onClearFilters,
            ),
          );
        }
        final items = state.items;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          sliver: SliverList.builder(
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == items.length) {
                return _Footer(state: state, onRetry: controller.loadMore);
              }
              final usta = items[index];
              // Each card repaints on its own (press animation, image fades)
              // without invalidating its neighbours.
              return RepaintBoundary(
                key: ValueKey(usta.id),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: UstaCard(usta: usta, userLocation: location),
                ),
              );
            },
          ),
        );
    }
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final UstaListState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (state.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: TextButton(
            onPressed: onRetry,
            child: const Text('Devamını yüklemedik · Tekrar dene'),
          ),
        ),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: Text(
            '${state.total} usta gösterildi',
            style: AppTypography.caption,
          ),
        ),
      );
    }
    return const SizedBox(height: AppSpacing.xl);
  }
}

class UstaListSkeleton extends StatelessWidget {
  const UstaListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonBox(width: 52, height: 52, radius: 14),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 160, height: 16),
                            SizedBox(height: 8),
                            SkeletonBox(width: 110, height: 12),
                            SizedBox(height: 10),
                            SkeletonBox(width: 90, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  SkeletonBox(height: 44, radius: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
