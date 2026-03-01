import 'package:equatable/equatable.dart';

class ReadingProgress extends Equatable {
  final String id;
  final String userId;
  final String clubId;
  final String bookId;
  final int? currentPage;
  final int? currentLocation;
  final int? currentTimestampSec;
  final double percentComplete;
  final DateTime updatedAt;

  const ReadingProgress({
    required this.id,
    required this.userId,
    required this.clubId,
    required this.bookId,
    this.currentPage,
    this.currentLocation,
    this.currentTimestampSec,
    this.percentComplete = 0.0,
    required this.updatedAt,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      clubId: json['club_id'] as String,
      bookId: json['book_id'] as String,
      currentPage: json['current_page'] as int?,
      currentLocation: json['current_location'] as int?,
      currentTimestampSec: json['current_timestamp_sec'] as int?,
      percentComplete: (json['percent_complete'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'club_id': clubId,
      'book_id': bookId,
      'current_page': currentPage,
      'current_location': currentLocation,
      'current_timestamp_sec': currentTimestampSec,
      'percent_complete': percentComplete,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  bool get isFinished => percentComplete >= 100.0;

  String get displayProgress {
    if (currentPage != null) return 'pg. $currentPage';
    if (currentLocation != null) return 'loc $currentLocation';
    if (currentTimestampSec != null) {
      final hours = currentTimestampSec! ~/ 3600;
      final minutes = (currentTimestampSec! % 3600) ~/ 60;
      final seconds = currentTimestampSec! % 60;
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${percentComplete.toStringAsFixed(0)}%';
  }

  @override
  List<Object?> get props => [id, userId, clubId, bookId, percentComplete];
}
