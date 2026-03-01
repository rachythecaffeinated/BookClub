import 'package:equatable/equatable.dart';

enum NoteVisibility { club, private_ }

class MarginNote extends Equatable {
  final String id;
  final String userId;
  final String clubId;
  final String bookId;
  final int? pageNumber;
  final int? locationNumber;
  final int? timestampSec;
  final double percentPosition;
  final String noteText;
  final String? quoteText;
  final NoteVisibility visibility;
  final DateTime createdAt;

  const MarginNote({
    required this.id,
    required this.userId,
    required this.clubId,
    required this.bookId,
    this.pageNumber,
    this.locationNumber,
    this.timestampSec,
    required this.percentPosition,
    required this.noteText,
    this.quoteText,
    this.visibility = NoteVisibility.club,
    required this.createdAt,
  });

  factory MarginNote.fromJson(Map<String, dynamic> json) {
    return MarginNote(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      clubId: json['club_id'] as String,
      bookId: json['book_id'] as String,
      pageNumber: json['page_number'] as int?,
      locationNumber: json['location_number'] as int?,
      timestampSec: json['timestamp_sec'] as int?,
      percentPosition: (json['percent_position'] as num).toDouble(),
      noteText: json['note_text'] as String,
      quoteText: json['quote_text'] as String?,
      visibility: json['visibility'] == 'private'
          ? NoteVisibility.private_
          : NoteVisibility.club,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'club_id': clubId,
      'book_id': bookId,
      'page_number': pageNumber,
      'location_number': locationNumber,
      'timestamp_sec': timestampSec,
      'percent_position': percentPosition,
      'note_text': noteText,
      'quote_text': quoteText,
      'visibility':
          visibility == NoteVisibility.private_ ? 'private' : 'club',
    };
  }

  @override
  List<Object?> get props => [id, userId, clubId, bookId, percentPosition];
}
