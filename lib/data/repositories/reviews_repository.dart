import '../../core/errors/app_failure.dart';
import '../datasources/remote_data_source.dart';
import '../models/paged.dart';
import '../models/review.dart';

class ReviewsPage extends Paged<Review> {
  const ReviewsPage({
    required super.items,
    required super.total,
    required super.page,
    required super.hasMore,
    required this.averageRating,
  });

  final double averageRating;
}

class ReviewsRepository {
  ReviewsRepository(this._remote);

  final RemoteDataSource _remote;

  Future<ReviewsPage> fetchPage(
    String providerId,
    int page, {
    int limit = 5,
  }) async {
    try {
      final json = await _remote.getReviews(
        providerId,
        page: page,
        limit: limit,
      );
      final items = (json['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Review.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
      return ReviewsPage(
        items: items,
        total: (json['total'] as num?)?.toInt() ?? items.length,
        page: page,
        hasMore: json['hasMore'] == true,
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      );
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw AppFailure.unknown;
    }
  }

  Future<Review> create(
    String providerId, {
    required double rating,
    required String comment,
    required String authorName,
    required String userId,
  }) async {
    try {
      return Review.fromJson(
        await _remote.createReview(providerId, {
          'rating': rating,
          'comment': comment,
          'authorName': authorName,
          'userId': userId,
        }),
      );
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw AppFailure.unknown;
    }
  }
}
