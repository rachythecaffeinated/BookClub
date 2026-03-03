import 'package:equatable/equatable.dart';

class BookProposal extends Equatable {
  final String id;
  final String bookPickId;
  final String proposedBy;
  final String title;
  final String author;
  final String? coverUrl;
  final int? pageCount;
  final String? isbn;
  final String? description;
  final List<String> votedBy;
  final int voteCount;
  final int totalScore;
  final bool eliminated;
  final int vetoCount;
  final DateTime createdAt;

  const BookProposal({
    required this.id,
    required this.bookPickId,
    required this.proposedBy,
    required this.title,
    required this.author,
    this.coverUrl,
    this.pageCount,
    this.isbn,
    this.description,
    this.votedBy = const [],
    this.voteCount = 0,
    this.totalScore = 0,
    this.eliminated = false,
    this.vetoCount = 0,
    required this.createdAt,
  });

  factory BookProposal.fromJson(Map<String, dynamic> json) {
    return BookProposal(
      id: json['id'] as String,
      bookPickId: json['book_pick_id'] as String,
      proposedBy: json['proposed_by'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      coverUrl: json['cover_url'] as String?,
      pageCount: json['page_count'] as int?,
      isbn: json['isbn'] as String?,
      description: json['description'] as String?,
      votedBy: List<String>.from(json['voted_by'] ?? []),
      voteCount: json['vote_count'] as int? ?? 0,
      totalScore: json['total_score'] as int? ?? 0,
      eliminated: json['eliminated'] as bool? ?? false,
      vetoCount: json['veto_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book_pick_id': bookPickId,
      'proposed_by': proposedBy,
      'title': title,
      'author': author,
      'cover_url': coverUrl,
      'page_count': pageCount,
      'isbn': isbn,
      'description': description,
      'voted_by': votedBy,
      'vote_count': voteCount,
      'total_score': totalScore,
      'eliminated': eliminated,
      'veto_count': vetoCount,
    };
  }

  @override
  List<Object?> get props => [id, bookPickId, title, author, voteCount];
}
