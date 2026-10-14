import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/debouncer.dart';
import '../../data/models/category.dart';
import '../../data/models/filter_state.dart';
import '../discovery/category_icons.dart';
import '../discovery/discovery_providers.dart';
import '../location/location_controller.dart';
import '../provider/widgets/usta_results.dart';

/// "Ara" tab: free-text search across every category, or browse the taxonomy.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer(AppDurations.debounce);
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // clear button visibility
    _debouncer.run(() {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _clear() {
    _controller.clear();
    setState(() => _query = '');
  }

  void _openDiscover(String categoryId, [String? subType]) {
    ref
        .read(filtersProvider.notifier)
        .selectCategoryAndSubType(categoryId, subType);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final searching = _query.length >= 2;
    final searchQuery = searching ? _searchQuery() : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _maybeLoadMore(
          searchQuery,
          CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.lg,
                    AppSpacing.gutter,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ara', style: AppTypography.display),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.search,
                        onChanged: _onChanged,
                        decoration: InputDecoration(
                          hintText: 'Usta, hizmet veya semt ara',
                          prefixIcon: const Icon(
                            PhosphorIconsRegular.magnifyingGlass,
                            size: 20,
                          ),
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Aramayı temizle',
                                  icon: const Icon(
                                    PhosphorIconsBold.x,
                                    size: 18,
                                  ),
                                  onPressed: _clear,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (searching)
                _SearchResults(query: searchQuery!)
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    0,
                    AppSpacing.gutter,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: categories.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) => _CategoryCard(
                      category: categories[i],
                      onOpen: _openDiscover,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ProviderQuery _searchQuery() {
    final sort = ref.watch(filtersProvider.select((f) => f.sortMode));
    final location = ref.watch(
      locationProvider.select((s) => s.hasLocation ? s.location : null),
    );
    return ProviderQuery(
      filters: FilterState(mainType: null, sortMode: sort, query: _query),
      userLat: location?.lat,
      userLng: location?.lng,
    );
  }

  Widget _maybeLoadMore(ProviderQuery? query, Widget child) =>
      query == null ? child : LoadMoreOnScroll(query: query, child: child);
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.query});

  final ProviderQuery query;

  @override
  Widget build(BuildContext context) {
    return UstaResultsSliver(
      query: query,
      emptyTitle: '“${query.filters.query}” için sonuç bulamadık.',
      emptyMessage: 'Yazımı kontrol et ya da kategorilere göz at.',
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onOpen});

  final ProviderCategory category;
  final void Function(String categoryId, [String? subType]) onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: '${category.name} kategorisindeki tüm ustalar',
            child: InkWell(
              borderRadius: AppRadius.borderLg,
              onTap: () => onOpen(category.id),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: AppRadius.borderMd,
                      ),
                      child: Icon(
                        categoryIcon(category.id, filled: true),
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(category.name, style: AppTypography.titleSm),
                    ),
                    const Icon(
                      PhosphorIconsBold.caretRight,
                      size: 16,
                      color: AppColors.inkSubtle,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final s in category.subTypes)
                  ActionChip(
                    label: Text(s.label),
                    labelStyle: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: AppColors.background,
                    side: const BorderSide(color: AppColors.border),
                    shape: const StadiumBorder(),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onPressed: () => onOpen(category.id, s.value),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
