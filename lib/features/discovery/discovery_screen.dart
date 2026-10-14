import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/category.dart';
import '../../data/models/filter_state.dart';
import '../location/location_controller.dart';
import '../provider/widgets/usta_results.dart';
import 'category_icons.dart';
import 'city_sheet.dart';
import 'discovery_providers.dart';
import 'filter_sheet.dart';
import 'location_banner.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(providerQueryProvider);
    final filters = query.filters;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LoadMoreOnScroll(
          query: query,
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(ustaListProvider(query).notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                const SliverToBoxAdapter(child: _CategoryRow()),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterBarDelegate(filters: filters),
                ),
                if (filters.sortMode == SortMode.nearest)
                  const SliverToBoxAdapter(child: LocationNotice()),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xs),
                ),
                UstaResultsSliver(
                  query: query,
                  onClearFilters: filters.hasActiveRefinements
                      ? ref.read(filtersProvider.notifier).reset
                      : null,
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(filtersProvider.select((f) => f.city));
    final hasLocation = ref.watch(
      locationProvider.select((s) => s.hasLocation),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.lg,
        AppSpacing.gutter,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: 'Konum: ${city ?? 'Tüm Türkiye'}. Değiştirmek için dokun',
            child: Material(
              color: AppColors.surface,
              shape: const StadiumBorder(
                side: BorderSide(color: AppColors.border),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => showCitySheet(context),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSpacing.minTap,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasLocation
                              ? PhosphorIconsFill.crosshair
                              : PhosphorIconsFill.mapPin,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            city ?? 'Tüm Türkiye',
                            style: AppTypography.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          PhosphorIconsBold.caretDown,
                          size: 14,
                          color: AppColors.inkMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Hangi ustaya\nihtiyacın var?',
            style: AppTypography.display,
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(filtersProvider.select((f) => f.mainType));

    return SizedBox(
      height: 96,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Row(
          children: [
            for (var i = 0; i < categories.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CategoryTile(
                  category: categories[i],
                  selected: categories[i].id == selected,
                  onTap: () => ref
                      .read(filtersProvider.notifier)
                      .selectCategory(categories[i].id),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ProviderCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${category.name} kategorisi',
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: AppRadius.borderLg,
          onTap: onTap,
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  categoryIcon(category.id, filled: selected),
                  size: 28,
                  color: selected ? AppColors.primary : AppColors.inkMuted,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  category.shortName,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.ink,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pinned: sub-type chips + sort control + filters button.
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  _FilterBarDelegate({required this.filters});

  final FilterState filters;

  static const double _extent = 112;

  @override
  double get minExtent => _extent;
  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _SubTypeChips(),
          const SizedBox(height: AppSpacing.sm),
          _SortRow(filters: filters),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterBarDelegate old) =>
      old.filters != filters;
}

class _SubTypeChips extends ConsumerWidget {
  const _SubTypeChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final mainType = ref.watch(filtersProvider.select((f) => f.mainType));
    final subType = ref.watch(filtersProvider.select((f) => f.subType));
    final category = categories.where((c) => c.id == mainType).firstOrNull;
    final subTypes = category?.subTypes ?? const <SubType>[];

    return SizedBox(
      height: AppSpacing.minTap,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        children: [
          _Chip(
            label: 'Tümü',
            selected: subType == null,
            onTap: () => ref.read(filtersProvider.notifier).selectSubType(null),
          ),
          for (final s in subTypes)
            _Chip(
              label: s.label,
              selected: subType == s.value,
              onTap: () =>
                  ref.read(filtersProvider.notifier).selectSubType(s.value),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: selected ? AppColors.ink : AppColors.surface,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? AppColors.ink : AppColors.border,
            ),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg + 2,
              ),
              constraints: const BoxConstraints(minHeight: 40),
              child: Text(
                label,
                style: AppTypography.label.copyWith(
                  color: selected ? AppColors.surface : AppColors.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortRow extends ConsumerWidget {
  const _SortRow({required this.filters});

  final FilterState filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRefinements = filters.distanceKm != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<SortMode>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: AppColors.surface,
                selectedBackgroundColor: AppColors.primarySoft,
                selectedForegroundColor: AppColors.primary,
                foregroundColor: AppColors.inkMuted,
                side: const BorderSide(color: AppColors.border),
                textStyle: AppTypography.label,
              ),
              segments: [
                for (final m in SortMode.values)
                  ButtonSegment(value: m, label: Text(m.label)),
              ],
              selected: {filters.sortMode},
              onSelectionChanged: (s) =>
                  ref.read(filtersProvider.notifier).setSort(s.first),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Semantics(
            button: true,
            label: 'Filtreler',
            child: Material(
              color: hasRefinements ? AppColors.primary : AppColors.surface,
              shape: CircleBorder(
                side: BorderSide(
                  color: hasRefinements ? AppColors.primary : AppColors.border,
                ),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => showFilterSheet(context),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    PhosphorIconsRegular.slidersHorizontal,
                    size: 20,
                    color: hasRefinements ? AppColors.onPrimary : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
