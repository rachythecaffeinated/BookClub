import 'package:equatable/equatable.dart';

enum RsvpStatus { going, maybe, notGoing }

class MeetingRsvp extends Equatable {
  final String id;
  final String meetingId;
  final String userId;
  final RsvpStatus status;
  final DateTime respondedAt;

  const MeetingRsvp({
    required this.id,
    required this.meetingId,
    required this.userId,
    required this.status,
    required this.respondedAt,
  });

  factory MeetingRsvp.fromJson(Map<String, dynamic> json) {
    return MeetingRsvp(
      id: json['id'] as String,
      meetingId: json['meeting_id'] as String,
      userId: json['user_id'] as String,
      status: _parseStatus(json['status'] as String),
      respondedAt: DateTime.parse(json['responded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meeting_id': meetingId,
      'user_id': userId,
      'status': _statusToString(status),
    };
  }

  static RsvpStatus _parseStatus(String value) {
    switch (value) {
      case 'going':
        return RsvpStatus.going;
      case 'maybe':
        return RsvpStatus.maybe;
      case 'not_going':
        return RsvpStatus.notGoing;
      default:
        return RsvpStatus.maybe;
    }
  }

  static String _statusToString(RsvpStatus status) {
    switch (status) {
      case RsvpStatus.going:
        return 'going';
      case RsvpStatus.maybe:
        return 'maybe';
      case RsvpStatus.notGoing:
        return 'not_going';
    }
  }

  @override
  List<Object?> get props => [id, meetingId, userId, status];
}
