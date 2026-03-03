import 'package:equatable/equatable.dart';

enum BookPickStatus { proposing, rating, completed }

class BookPick extends Equatable {
  final String id;
  final String clubId;
  final String createdBy;
  final BookPickStatus status;
  final int memberCount;
  final int participantCount;
  final int ratingCount;
  final String? winnerProposalId;
  final String? winnerTitle;
  final List<String>? tiedProposalIds;
  final bool tiebroken;
  final DateTime createdAt;
  final DateTime? completedAt;

  const BookPick({
    required this.id,
    required this.clubId,
    required this.createdBy,
    this.status = BookPickStatus.proposing,
    required this.memberCount,
    this.participantCount = 0,
    this.ratingCount = 0,
    this.winnerProposalId,
    this.winnerTitle,
    this.tiedProposalIds,
    this.tiebroken = false,
    required this.createdAt,
    this.completedAt,
  });

  factory BookPick.fromJson(Map<String, dynamic> json) {
    return BookPick(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      createdBy: json['created_by'] as String,
      status: _parseStatus(json['status'] as String),
      memberCount: json['member_count'] as int,
      participantCount: json['participant_count'] as int? ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      winnerProposalId: json['winner_proposal_id'] as String?,
      winnerTitle: json['winner_title'] as String?,
      tiedProposalIds: json['tied_proposal_ids'] != null
          ? List<String>.from(json['tied_proposal_ids'] as List)
          : null,
      tiebroken: json['tiebroken'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'club_id': clubId,
      'created_by': createdBy,
      'status': status.name,
      'member_count': memberCount,
      'participant_count': participantCount,
      'rating_count': ratingCount,
      'winner_proposal_id': winnerProposalId,
      'winner_title': winnerTitle,
      if (tiedProposalIds != null) 'tied_proposal_ids': tiedProposalIds,
      'tiebroken': tiebroken,
    };
  }

  bool get isProposing => status == BookPickStatus.proposing;
  bool get isRating => status == BookPickStatus.rating;
  bool get isCompleted => status == BookPickStatus.completed;
  bool get hasTie =>
      isCompleted && winnerProposalId == null && (tiedProposalIds?.isNotEmpty ?? false);

  static BookPickStatus _parseStatus(String value) {
    switch (value) {
      case 'proposing':
        return BookPickStatus.proposing;
      case 'rating':
        return BookPickStatus.rating;
      case 'completed':
        return BookPickStatus.completed;
      default:
        return BookPickStatus.proposing;
    }
  }

  @override
  List<Object?> get props => [id, clubId, status, winnerProposalId, tiebroken];
}
