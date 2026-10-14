import 'package:equatable/equatable.dart';

class Review extends Equatable {
  const Review({
    required this.id,
    required this.providerId,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String providerId;
  final String authorName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: (json['id'] ?? '').toString(),
    providerId: (json['providerId'] ?? '').toString(),
    authorName: (json['authorName'] ?? 'Kullanıcı').toString(),
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    comment: (json['comment'] ?? '').toString(),
    createdAt:
        DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal() ??
        DateTime.now(),
  );

  @override
  List<Object?> get props => [id];
}
