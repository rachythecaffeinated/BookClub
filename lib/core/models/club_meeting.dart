import 'package:equatable/equatable.dart';

enum MeetingType { inPerson, virtual, hybrid }

class ClubMeeting extends Equatable {
  final String id;
  final String clubId;
  final String title;
  final String? description;
  final MeetingType meetingType;
  final String? locationName;
  final String? locationAddress;
  final double? locationLat;
  final double? locationLng;
  final String? virtualLink;
  final DateTime startsAt;
  final int durationMinutes;
  final double? readingTargetPercent;
  final int? readingTargetPage;
  final String? recurrence;
  final String? recurrenceParentId;
  final List<int> reminderOffsets;
  final String createdBy;
  final bool cancelled;
  final DateTime createdAt;

  const ClubMeeting({
    required this.id,
    required this.clubId,
    required this.title,
    this.description,
    required this.meetingType,
    this.locationName,
    this.locationAddress,
    this.locationLat,
    this.locationLng,
    this.virtualLink,
    required this.startsAt,
    this.durationMinutes = 60,
    this.readingTargetPercent,
    this.readingTargetPage,
    this.recurrence,
    this.recurrenceParentId,
    this.reminderOffsets = const [1440, 60],
    required this.createdBy,
    this.cancelled = false,
    required this.createdAt,
  });

  factory ClubMeeting.fromJson(Map<String, dynamic> json) {
    return ClubMeeting(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      meetingType: _parseMeetingType(json['meeting_type'] as String),
      locationName: json['location_name'] as String?,
      locationAddress: json['location_address'] as String?,
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      virtualLink: json['virtual_link'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      readingTargetPercent:
          (json['reading_target_percent'] as num?)?.toDouble(),
      readingTargetPage: json['reading_target_page'] as int?,
      recurrence: json['recurrence'] as String?,
      recurrenceParentId: json['recurrence_parent_id'] as String?,
      reminderOffsets: (json['reminder_offsets'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [1440, 60],
      createdBy: json['created_by'] as String,
      cancelled: json['cancelled'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'club_id': clubId,
      'title': title,
      'description': description,
      'meeting_type': _meetingTypeToString(meetingType),
      'location_name': locationName,
      'location_address': locationAddress,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'virtual_link': virtualLink,
      'starts_at': startsAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'reading_target_percent': readingTargetPercent,
      'reading_target_page': readingTargetPage,
      'recurrence': recurrence,
      'reminder_offsets': reminderOffsets,
      'created_by': createdBy,
      'cancelled': cancelled,
    };
  }

  bool get isUpcoming => startsAt.isAfter(DateTime.now()) && !cancelled;

  static MeetingType _parseMeetingType(String value) {
    switch (value) {
      case 'in_person':
        return MeetingType.inPerson;
      case 'virtual':
        return MeetingType.virtual;
      case 'hybrid':
        return MeetingType.hybrid;
      default:
        return MeetingType.inPerson;
    }
  }

  static String _meetingTypeToString(MeetingType type) {
    switch (type) {
      case MeetingType.inPerson:
        return 'in_person';
      case MeetingType.virtual:
        return 'virtual';
      case MeetingType.hybrid:
        return 'hybrid';
    }
  }

  @override
  List<Object?> get props => [id, clubId, title, startsAt, cancelled];
}
