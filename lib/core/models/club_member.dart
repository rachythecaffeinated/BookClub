import 'package:equatable/equatable.dart';

enum MemberRole { admin, member }

enum MemberStatus { pending, accepted, declined }

enum ClubReadingFormat { sameEdition, diffEdition, kindle, audiobook, other }

class ClubMember extends Equatable {
  final String id;
  final String clubId;
  final String userId;
  final MemberRole role;
  final MemberStatus status;
  final ClubReadingFormat? readingFormat;
  final String? formatTotal;
  final String? customEndpoint;
  final DateTime? joinedAt;
  final String? invitedBy;

  const ClubMember({
    required this.id,
    required this.clubId,
    required this.userId,
    this.role = MemberRole.member,
    this.status = MemberStatus.pending,
    this.readingFormat,
    this.formatTotal,
    this.customEndpoint,
    this.joinedAt,
    this.invitedBy,
  });

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    return ClubMember(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] == 'admin' ? MemberRole.admin : MemberRole.member,
      status: MemberStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MemberStatus.pending,
      ),
      readingFormat: _parseReadingFormat(json['reading_format'] as String?),
      formatTotal: json['format_total'] as String?,
      customEndpoint: json['custom_endpoint'] as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      invitedBy: json['invited_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'club_id': clubId,
      'user_id': userId,
      'role': role.name,
      'status': status.name,
      'reading_format': _formatToString(readingFormat),
      'format_total': formatTotal,
      'custom_endpoint': customEndpoint,
      'invited_by': invitedBy,
    };
  }

  bool get isAdmin => role == MemberRole.admin;
  bool get isAccepted => status == MemberStatus.accepted;

  static ClubReadingFormat? _parseReadingFormat(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'same_edition':
        return ClubReadingFormat.sameEdition;
      case 'diff_edition':
        return ClubReadingFormat.diffEdition;
      case 'kindle':
        return ClubReadingFormat.kindle;
      case 'audiobook':
        return ClubReadingFormat.audiobook;
      case 'other':
        return ClubReadingFormat.other;
      default:
        return null;
    }
  }

  static String? _formatToString(ClubReadingFormat? format) {
    if (format == null) return null;
    switch (format) {
      case ClubReadingFormat.sameEdition:
        return 'same_edition';
      case ClubReadingFormat.diffEdition:
        return 'diff_edition';
      case ClubReadingFormat.kindle:
        return 'kindle';
      case ClubReadingFormat.audiobook:
        return 'audiobook';
      case ClubReadingFormat.other:
        return 'other';
    }
  }

  @override
  List<Object?> get props => [id, clubId, userId, role, status];
}
