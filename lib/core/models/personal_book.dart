import 'package:equatable/equatable.dart';

enum Shelf { reading, wantToRead, finished }

enum PersonalReadingFormat { physical, kindle, audiobook, ebook, other }

class PersonalBook extends Equatable {
  final String id;
  final String userId;
  final String bookId;
  final String? title;
  final String? author;
  final String? coverUrl;
  final Shelf shelf;
  final bool isOwned;
  final PersonalReadingFormat? readingFormat;
  final String? formatTotal;
  final String? customEndpoint;
  final int? currentPage;
  final int? currentLocation;
  final int? currentTimestampSec;
  final double percentComplete;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime createdAt;

  const PersonalBook({
    required this.id,
    required this.userId,
    required this.bookId,
    this.title,
    this.author,
    this.coverUrl,
    this.shelf = Shelf.reading,
    this.isOwned = false,
    this.readingFormat,
    this.formatTotal,
    this.customEndpoint,
    this.currentPage,
    this.currentLocation,
    this.currentTimestampSec,
    this.percentComplete = 0.0,
    this.startedAt,
    this.finishedAt,
    required this.createdAt,
  });

  factory PersonalBook.fromJson(Map<String, dynamic> json) {
    return PersonalBook(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookId: json['book_id'] as String,
      title: json['title'] as String?,
      author: json['author'] as String?,
      coverUrl: json['cover_url'] as String?,
      shelf: _parseShelf(json['shelf'] as String),
      isOwned: json['is_owned'] as bool? ?? false,
      readingFormat: _parseFormat(json['reading_format'] as String?),
      formatTotal: json['format_total'] as String?,
      customEndpoint: json['custom_endpoint'] as String?,
      currentPage: json['current_page'] as int?,
      currentLocation: json['current_location'] as int?,
      currentTimestampSec: json['current_timestamp_sec'] as int?,
      percentComplete: (json['percent_complete'] as num?)?.toDouble() ?? 0.0,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'book_id': bookId,
      'title': title,
      'author': author,
      'cover_url': coverUrl,
      'shelf': _shelfToString(shelf),
      'is_owned': isOwned,
      'reading_format': _formatToString(readingFormat),
      'format_total': formatTotal,
      'custom_endpoint': customEndpoint,
      'current_page': currentPage,
      'current_location': currentLocation,
      'current_timestamp_sec': currentTimestampSec,
      'percent_complete': percentComplete,
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
    };
  }

  static Shelf _parseShelf(String value) {
    switch (value) {
      case 'reading':
        return Shelf.reading;
      case 'want_to_read':
        return Shelf.wantToRead;
      case 'finished':
        return Shelf.finished;
      default:
        return Shelf.reading;
    }
  }

  static String _shelfToString(Shelf shelf) {
    switch (shelf) {
      case Shelf.reading:
        return 'reading';
      case Shelf.wantToRead:
        return 'want_to_read';
      case Shelf.finished:
        return 'finished';
    }
  }

  static PersonalReadingFormat? _parseFormat(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'physical':
        return PersonalReadingFormat.physical;
      case 'kindle':
        return PersonalReadingFormat.kindle;
      case 'audiobook':
        return PersonalReadingFormat.audiobook;
      case 'ebook':
        return PersonalReadingFormat.ebook;
      case 'other':
        return PersonalReadingFormat.other;
      default:
        return null;
    }
  }

  static String? _formatToString(PersonalReadingFormat? format) {
    return format?.name;
  }

  @override
  List<Object?> get props => [id, userId, bookId, shelf, isOwned, percentComplete];
}
