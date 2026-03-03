import 'package:equatable/equatable.dart';

class BookRating extends Equatable {
  final String id;
  final String bookPickId;
  final String userId;
  final Map<String, int> ratings;
  final DateTime createdAt;

  const BookRating({
    required this.id,
    required this.bookPickId,
    required this.userId,
    required this.ratings,
    required this.createdAt,
  });

  factory BookRating.fromJson(Map<String, dynamic> json) {
    return BookRating(
      id: json['id'] as String,
      bookPickId: json['book_pick_id'] as String,
      userId: json['user_id'] as String,
      ratings: Map<String, int>.from(json['ratings'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book_pick_id': bookPickId,
      'user_id': userId,
      'ratings': ratings,
    };
  }

  @override
  List<Object?> get props => [id, bookPickId, userId];
}
