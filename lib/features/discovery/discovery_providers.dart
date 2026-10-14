import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/categories.dart';
import '../../core/errors/app_failure.dart';
import '../../data/models/category.dart';
import '../../data/models/filter_state.dart';
import '../../data/models/usta.dart';
import '../../data/providers.dart';
import '../location/location_controller.dart';

// ── Categories: built-in list first, API refresh in the background ─────────
class CategoriesController extends Notifier<List<ProviderCategory>> {
  @override
  List<ProviderCategory> build() {
    Future.microtask(() async {
      try {
        final remote = await ref.read(ustaRepositoryProvider).fetchCategories();
        if (ref.mounted && remote.isNotEmpty) state = remote;
      } catch (_) {
        // Keep the built-in taxonomy.
      }
    });
    return kBuiltInCategories;
  }
}

final categoriesProvider =
    NotifierProvider<CategoriesController, List<ProviderCategory>>(
      CategoriesController.new,
    );

// ── Filters ─────────────────────────────────────────────────────────────────
class FiltersController extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void selectCategory(String id) {
    if (id == state.mainType && state.subType == null) return;
    state = state.copyWith(mainType: id, clearSubType: true);
  }

  void selectCategoryAndSubType(String id, String? subType) {
    state = subType == null
        ? state.copyWith(mainType: id, clearSubType: true)
        : state.copyWith(mainType: id, subType: subType);
  }

  void selectSubType(String? value) => state = value == null
      ? state.copyWith(clearSubType: true)
      : state.copyWith(subType: value);

  void setCity(String? city) => state = city == null
      ? state.copyWith(clearCity: true)
      : state.copyWith(city: city);

  void setSort(SortMode mode) => state = state.copyWith(sortMode: mode);

  void setDistance(double? km) => state = km == null
      ? state.copyWith(clearDistance: true)
      : state.copyWith(distanceKm: km);

  void reset() =>
      state = FilterState(mainType: state.mainType, sortMode: state.sortMode);
}

final filtersProvider = NotifierProvider<FiltersController, FilterState>(
  FiltersController.new,
);

/// Filters + coordinates (only real ones) = the key of a provider list.
final providerQueryProvider = Provider<ProviderQuery>((ref) {
  final filters = ref.watch(filtersProvider);
  final location = ref.watch(
    locationProvider.select((s) => s.hasLocation ? s.location : null),
  );
  return ProviderQuery(
    filters: filters,
    userLat: location?.lat,
    userLng: location?.lng,
  );
});

// ── Paginated provider list ─────────────────────────────────────────────────
enum ListStatus { loading, data, error }

class UstaListState {
  const UstaListState({
    this.status = ListStatus.loading,
    this.items = const [],
    this.total = 0,
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.failure,
  });

  final ListStatus status;
  final List<Usta> items;
  final int total;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final AppFailure? failure;

  UstaListState copyWith({
    ListStatus? status,
    List<Usta>? items,
    int? total,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    AppFailure? failure,
  }) => UstaListState(
    status: status ?? this.status,
    items: items ?? this.items,
    total: total ?? this.total,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    failure: failure,
  );
}

class UstaListController extends Notifier<UstaListState> {
  UstaListController(this.query);

  final ProviderQuery query;

  @override
  UstaListState build() {
    Future.microtask(_loadFirstPage);
    return const UstaListState();
  }

  Future<void> _loadFirstPage() async {
    try {
      final page = await ref.read(ustaRepositoryProvider).fetchPage(query, 1);
      if (!ref.mounted) return;
      state = UstaListState(
        status: ListStatus.data,
        items: page.items,
        total: page.total,
        page: 1,
        hasMore: page.hasMore,
      );
    } catch (e) {
      if (!ref.mounted) return;
      // On a failed refresh keep what the user already sees.
      state = state.items.isEmpty
          ? UstaListState(status: ListStatus.error, failure: AppFailure.from(e))
          : state.copyWith(status: ListStatus.data);
    }
  }

  /// Pull-to-refresh and the error-state retry button.
  Future<void> refresh() async {
    if (state.items.isEmpty) state = const UstaListState();
    await _loadFirstPage();
  }

  Future<void> loadMore() async {
    if (state.status != ListStatus.data ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final next = await ref
          .read(ustaRepositoryProvider)
          .fetchPage(query, state.page + 1);
      if (!ref.mounted) return;
      final known = state.items.map((e) => e.id).toSet();
      state = state.copyWith(
        items: [
          ...state.items,
          ...next.items.where((e) => !known.contains(e.id)),
        ],
        page: next.page,
        total: next.total,
        hasMore: next.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoadingMore: false, loadMoreFailed: true);
    }
  }
}

final ustaListProvider = NotifierProvider.autoDispose
    .family<UstaListController, UstaListState, ProviderQuery>(
      UstaListController.new,
    );

// ── Detail ──────────────────────────────────────────────────────────────────
final ustaDetailProvider = FutureProvider.autoDispose.family<Usta, String>(
  (ref, id) => ref.watch(ustaRepositoryProvider).getById(id),
);
