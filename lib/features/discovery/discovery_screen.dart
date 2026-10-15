import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/debouncer.dart';
import '../../data/models/category.dart';
import '../../data/models/filter_state.dart';
import '../location/location_controller.dart';
import '../provider/widgets/usta_results.dart';
import 'category_icons.dart';
import 'city_sheet.dart';
import 'discovery_providers.dart';
import 'filter_sheet.dart';
import 'location_banner.dart';
import 'sort_sheet.dart';

/// Home: what do you need, where, who matches. One scrolling page, no tabs inside tabs.
class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(providerQueryProvider);
    final filters = query.filters;
    final gutter = context.ui.gutter;

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
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  sliver: const SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      SizedBox(height: AppSpacing.xl),
                      _Header(),
                      SizedBox(height: AppSpacing.lg),
                      _SearchField(),
                      SizedBox(height: AppSpacing.xs),
                      _LocationRow(),
                      SizedBox(height: AppSpacing.md),
                      _CategoryGrid(),
                      SizedBox(height: AppSpacing.xxl),
                      _ResultsHeader(),
                    ]),
                  ),
                ),
                if (filters.sortMode == SortMode.nearest)
                  const SliverToBoxAdapter(child: LocationNotice()),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xs),
                ),
                UstaResultsSliver(
                  query: query,
                  onClearFilters:
                      filters.hasActiveRefinements ||
                          filters.mainType != null ||
                          filters.searching
                      ? ref.read(filtersProvider.notifier).clearAll
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: const Text(
        'Hangi ustaya ihtiyacın var?',
        style: AppTypography.display,
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer(AppDurations.debounce);

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    _debouncer.cancel();
    ref.read(filtersProvider.notifier).setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    // Keep the field in step when "Temizle" or a category tap resets the search.
    ref.listen(filtersProvider.select((f) => f.query), (_, next) {
      if (next != _controller.text) _controller.text = next;
    });

    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      style: AppTypography.body,
      onChanged: (v) {
        setState(() {});
        _debouncer.run(() {
          if (mounted) ref.read(filtersProvider.notifier).setQuery(v);
        });
      },
      decoration: InputDecoration(
        hintText: 'Ne hizmeti arıyorsun?',
        prefixIcon: const Padding(
          padding: EdgeInsets.all(AppSpacing.md + 2),
          child: UstaIcon(
            UstaIcons.search,
            size: 24,
            color: AppColors.inkMuted,
          ),
        ),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Aramayı temizle',
                icon: const UstaIcon(UstaIcons.close, size: 22),
                onPressed: _clear,
              ),
      ),
    );
  }
}

class _LocationRow extends ConsumerWidget {
  const _LocationRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(filtersProvider.select((f) => f.city));
    final hasLocation = ref.watch(
      locationProvider.select((s) => s.hasLocation),
    );
    final place =
        city ?? (hasLocation ? 'Konumun kullanılıyor' : 'Tüm Türkiye');

    return Semantics(
      button: true,
      label: 'Konum: $place. Değiştirmek için dokun',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadius.borderMd,
        onTap: () => showCitySheet(context),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.ui.tapTarget),
          child: Row(
            // Both sides keep their natural width; the free space goes between them,
            // and either side shrinks (with an ellipsis) before anything overflows.
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UstaIcon(
                      hasLocation ? UstaIcons.locate : UstaIcons.pin,
                      size: 22,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        place,
                        style: AppTypography.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  'Değiştir',
                  style: AppTypography.label.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(filtersProvider.select((f) => f.mainType));
    final notifier = ref.read(filtersProvider.notifier);

    // Big text (OS font size or Usta UI size) gets wider, side-by-side tiles.
    final roomy = MediaQuery.textScalerOf(context).scale(16) > 17.5;
    final columns = roomy ? 2 : 3;

    // First tile = "all services", then every category.
    final tiles = <Widget>[
      _CategoryTile(
        label: 'Tüm hizmetler',
        icon: categoryIcon(null),
        selected: selected == null,
        horizontal: roomy,
        onTap: () => notifier.selectCategory(null),
      ),
      for (final ProviderCategory c in categories)
        _CategoryTile(
          label: c.name,
          icon: categoryIcon(c.id),
          selected: c.id == selected,
          horizontal: roomy,
          onTap: () => notifier.selectCategory(c.id),
        ),
    ];

    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += columns) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: i + j < tiles.length
                        ? tiles[i + j]
                        : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.horizontal,
    required this.onTap,
  });

  final String label;
  final UstaIconData icon;
  final bool selected;
  final bool horizontal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppColors.primary : AppColors.inkMuted;
    final text = Text(
      label,
      textAlign: horizontal ? TextAlign.start : TextAlign.center,
      style: AppTypography.label.copyWith(
        fontSize: 14,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: horizontal ? context.ui.rowHeight + 8 : 92,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.md,
              ),
              child: horizontal
                  ? Row(
                      children: [
                        UstaIcon(icon, size: 28, color: iconColor),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: text),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        UstaIcon(icon, size: 28, color: iconColor),
                        const SizedBox(height: AppSpacing.sm),
                        text,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

final _compactButton = OutlinedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
);

/// Heading, the two controls (sort / filter) and a plain-language summary of what is applied.
class _ResultsHeader extends ConsumerWidget {
  const _ResultsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(providerQueryProvider);
    final filters = query.filters;
    final categories = ref.watch(categoriesProvider);
    final total = ref.watch(
      ustaListProvider(query)
          .select((s) => s.status == ListStatus.data ? s.total : null),
    );

    final heading = filters.searching
        ? 'Arama sonuçları'
        : (query.hasLocation ? 'Yakınındaki ustalar' : 'Ustalar');
    final summary = _summary(filters, categories);
    final filterCount = filters.activeFilterCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(heading, style: AppTypography.title),
              ),
            ),
            if (total != null) Text('$total usta', style: AppTypography.bodySm),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: OutlinedButton(
                style: _compactButton,
                onPressed: () => showSortSheet(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Sırala: ${filters.sortMode.shortLabel}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const UstaIcon(UstaIcons.chevronDown, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: OutlinedButton(
                style: filterCount > 0
                    ? _compactButton.copyWith(
                        side: const WidgetStatePropertyAll(AppBorders.selected),
                        backgroundColor: const WidgetStatePropertyAll(
                          AppColors.primarySoft,
                        ),
                      )
                    : _compactButton,
                onPressed: () => showFilterSheet(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const UstaIcon(UstaIcons.sliders, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        filterCount > 0
                            ? 'Filtrele ($filterCount)'
                            : 'Filtrele',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(child: Text(summary, style: AppTypography.bodySm)),
              TextButton(
                onPressed: ref.read(filtersProvider.notifier).clearAll,
                child: const Text('Temizle'),
              ),
            ],
          ),
        ] else
          const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  /// "Klima Servisi · İzmir · 10 km içinde"
  static String _summary(FilterState f, List<ProviderCategory> categories) {
    final category = categories.where((c) => c.id == f.mainType).firstOrNull;
    final subLabel = category?.subTypes
        .where((s) => s.value == f.subType)
        .firstOrNull
        ?.label;
    return [
      if (f.searching) '“${f.query.trim()}”',
      if (subLabel != null) subLabel else ?category?.name,
      ?f.city,
      if (f.distanceKm != null) '${f.distanceKm!.round()} km içinde',
    ].join(' · ');
  }
}
