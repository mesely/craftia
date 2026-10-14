import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../data/models/review.dart';
import '../../data/providers.dart';

class ReviewsState {
  const ReviewsState({
    this.loading = true,
    this.items = const [],
    this.total = 0,
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.averageRating = 0,
    this.failure,
  });

  final bool loading;
  final List<Review> items;
  final int total;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final double averageRating;
  final AppFailure? failure;

  ReviewsState copyWith({
    bool? loading,
    List<Review>? items,
    int? total,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    double? averageRating,
    AppFailure? failure,
  }) => ReviewsState(
    loading: loading ?? this.loading,
    items: items ?? this.items,
    total: total ?? this.total,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    averageRating: averageRating ?? this.averageRating,
    failure: failure,
  );
}

class ReviewsController extends Notifier<ReviewsState> {
  ReviewsController(this.providerId);

  final String providerId;

  @override
  ReviewsState build() {
    Future.microtask(load);
    return const ReviewsState();
  }

  Future<void> load() async {
    state = const ReviewsState();
    try {
      final page = await ref
          .read(reviewsRepositoryProvider)
          .fetchPage(providerId, 1);
      if (!ref.mounted) return;
      state = ReviewsState(
        loading: false,
        items: page.items,
        total: page.total,
        page: 1,
        hasMore: page.hasMore,
        averageRating: page.averageRating,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = ReviewsState(loading: false, failure: AppFailure.from(e));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = await ref
          .read(reviewsRepositoryProvider)
          .fetchPage(providerId, state.page + 1);
      if (!ref.mounted) return;
      state = state.copyWith(
        items: [...state.items, ...next.items],
        page: next.page,
        hasMore: next.hasMore,
        loadingMore: false,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(loadingMore: false);
    }
  }

  /// Throws [AppFailure] so the sheet can show the message.
  Future<void> submit({
    required double rating,
    required String comment,
    required String authorName,
  }) async {
    final userId = await ref.read(deviceIdProvider.future);
    await ref
        .read(reviewsRepositoryProvider)
        .create(
          providerId,
          rating: rating,
          comment: comment,
          authorName: authorName,
          userId: userId,
        );
    if (ref.mounted) await load();
  }
}

final reviewsProvider = NotifierProvider.autoDispose
    .family<ReviewsController, ReviewsState, String>(ReviewsController.new);
