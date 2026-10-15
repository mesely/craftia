import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/constants/services.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/debouncer.dart';
import '../../data/models/filter_state.dart';
import '../location/location_controller.dart';
import '../location/place_name.dart';
import '../provider/widgets/usta_results.dart';
import 'city_sheet.dart';
import 'discovery_providers.dart';
import 'distance_sheet.dart';
import 'location_banner.dart';
import 'service_tile.dart';
import 'sort_sheet.dart';

/// Home: what do you need, where, who matches. One scrolling page, no tabs inside tabs.
/// There is exactly one way to choose a kind of work (the picture tiles) and one place to
/// say where (the location line); sorting and distance sit with the results they change.
class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final _resultsKey = GlobalKey();

  /// After picking a service, bring the results into view: one tap, then the answer.
  void _showResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultsKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: AppDurations.slow,
          curve: Curves.easeOutCubic,
          alignment: 0.02,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(filtersProvider.select((f) => f.subType), (prev, next) {
      if (next != null && next != prev) _showResults();
    });
    final query = ref.watch(providerQueryProvider);
    final filters = query.filters;
    final gutter = context.ui.gutter;

    return LoadMoreOnScroll(
      query: query,
      child: RefreshIndicator(
        onRefresh: () => ref.read(ustaListProvider(query).notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  const SizedBox(height: AppSpacing.xs),
                  const _Header(),
                  const SizedBox(height: AppSpacing.sm),
                  const _SearchField(),
                  const _LocationRow(),
                  const _ServiceTiles(),
                  const SizedBox(height: AppSpacing.lg),
                  KeyedSubtree(key: _resultsKey, child: const _ResultsHeader()),
                ]),
              ),
            ),
            if (filters.sortMode == SortMode.nearest)
              const SliverToBoxAdapter(child: LocationNotice()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),
            UstaResultsSliver(
              query: query,
              onClearFilters: filters.hasActiveRefinements || filters.searching
                  ? ref.read(filtersProvider.notifier).clearAll
                  : null,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],
        ),
      ),
    );
  }
}

/// One line at normal size; wraps rather than shrinks when text is large.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final text = Text(
      'Hangi ustaya ihtiyacın var?',
      style: AppTypography.titleSm.copyWith(fontSize: 19),
    );
    final roomy = MediaQuery.textScalerOf(context).scale(16) > 17.5;
    return Semantics(
      header: true,
      child: roomy
          ? text
          : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: text,
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
    // Keep the field in step when "Temizle" or a service tap resets the search.
    ref.listen(filtersProvider.select((f) => f.query), (_, next) {
      if (next != _controller.text) _controller.text = next;
    });

    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      style: AppTypography.body.copyWith(fontSize: 15),
      onChanged: (v) {
        setState(() {});
        _debouncer.run(() {
          if (mounted) ref.read(filtersProvider.notifier).setQuery(v);
        });
      },
      decoration: InputDecoration(
        hintText: 'Usta ya da hizmet ara',
        isDense: true,
        constraints: BoxConstraints(minHeight: context.ui.tapTarget - 6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 2,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: UstaIcon(
            UstaIcons.search,
            size: 20,
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

/// "Karşıyaka, İzmir  Değiştir": where we are looking. Uses the phone's place name when the
/// location is on, the chosen city otherwise.
class _LocationRow extends ConsumerWidget {
  const _LocationRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(filtersProvider.select((f) => f.city));
    final hasLocation = ref.watch(
      locationProvider.select((s) => s.hasLocation),
    );
    final placeName = hasLocation
        ? ref.watch(currentPlaceNameProvider).value
        : null;
    final place =
        city ?? placeName ?? (hasLocation ? 'Bulunduğun yer' : 'Tüm Türkiye');

    return Semantics(
      button: true,
      label: 'Konum: $place. Değiştirmek için dokun',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadius.borderMd,
        onTap: () => showCitySheet(context),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.ui.tapTarget - 8),
          child: Row(
            // Either side shrinks (with an ellipsis) before anything overflows.
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UstaIcon(
                      hasLocation && city == null
                          ? UstaIcons.locate
                          : UstaIcons.pin,
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

class _ServiceTiles extends ConsumerWidget {
  const _ServiceTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(filtersProvider.select((f) => f.subType));
    final notifier = ref.read(filtersProvider.notifier);
    final id = kServices
        .where((s) => s.subType == selected)
        .map((s) => s.id)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ServiceGrid(
          selectedId: id,
          onSelect: notifier.selectService,
          compact: true,
        ),
      ],
    );
  }
}

/// Heading, the two controls (sort / distance) and a plain-language summary of what is applied.
class _ResultsHeader extends ConsumerWidget {
  const _ResultsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(providerQueryProvider);
    final filters = query.filters;

    final summary = _summary(filters);

    final sortLabel = filters.sortMode.shortLabel;
    final distanceLabel = filters.distanceKm == null
        ? 'Uzaklık'
        : '${filters.distanceKm!.round()} km';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort on the left half, distance on the right half: a balanced pair.
        Row(
          children: [
            Expanded(
              child: _MiniButton(
                label: sortLabel,
                semantic: 'Sırala: $sortLabel',
                onTap: () => showSortSheet(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MiniButton(
                label: distanceLabel,
                semantic: filters.distanceKm == null
                    ? 'Uzaklık seç'
                    : '${filters.distanceKm!.round()} kilometre içinde',
                onTap: () => showDistanceSheet(context),
              ),
            ),
          ],
        ),
        if (summary.isNotEmpty)
          Row(
            children: [
              Expanded(child: Text(summary, style: AppTypography.bodySm)),
              TextButton(
                onPressed: ref.read(filtersProvider.notifier).clearAll,
                child: const Text('Temizle'),
              ),
            ],
          ),
      ],
    );
  }

  /// "Klima & Kombi · İzmir · 10 km içinde"
  static String _summary(FilterState f) {
    final service = serviceFor(subType: f.subType)?.label;
    return [
      if (f.searching) '“${f.query.trim()}”',
      ?service,
      ?f.city,
      if (f.distanceKm != null) '${f.distanceKm!.round()} km içinde',
    ].join(' · ');
  }
}

/// A small outlined control with a chevron: "En yakın ⌄".
class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.semantic,
    required this.onTap,
  });

  final String label;
  final String semantic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic,
      excludeSemantics: true,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, context.ui.tapTarget - 6),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          textStyle: AppTypography.button.copyWith(fontSize: 14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 2),
            const UstaIcon(UstaIcons.chevronDown, size: 16),
          ],
        ),
      ),
    );
  }
}
