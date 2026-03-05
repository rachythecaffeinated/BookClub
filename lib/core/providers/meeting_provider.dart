import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/club_meeting.dart';
import '../services/firebase_service.dart';

/// Fetches a single meeting by ID.
final meetingDetailProvider = FutureProvider.autoDispose
    .family<ClubMeeting?, ({String clubId, String meetingId})>(
        (ref, params) async {
  final doc = await FirebaseService.clubMeetings(params.clubId)
      .doc(params.meetingId)
      .get();
  if (!doc.exists) return null;
  return ClubMeeting.fromJson(
    FirebaseService.docToJson(doc, extra: {'club_id': params.clubId}),
  );
});

/// Fetches the next upcoming meeting for a club.
final nextMeetingProvider = FutureProvider.autoDispose
    .family<ClubMeeting?, String>((ref, clubId) async {
  final snapshot = await FirebaseService.clubMeetings(clubId)
      .where('starts_at',
          isGreaterThan: DateTime.now().toIso8601String())
      .where('cancelled', isEqualTo: false)
      .orderBy('starts_at')
      .limit(1)
      .get();

  if (snapshot.docs.isEmpty) return null;
  return ClubMeeting.fromJson(
    FirebaseService.docToJson(snapshot.docs.first,
        extra: {'club_id': clubId}),
  );
});

/// Fetches the current user's RSVP status for a meeting.
final myRsvpProvider = FutureProvider.autoDispose
    .family<String?, ({String clubId, String meetingId})>(
        (ref, params) async {
  final userId = FirebaseService.currentUserId;
  if (userId == null) return null;

  final doc = await FirebaseService.meetingRsvps(params.clubId, params.meetingId)
      .doc(userId)
      .get();
  if (!doc.exists) return null;
  return doc.data()?['status'] as String?;
});

/// Notifier for meeting actions (create, RSVP).
class MeetingNotifier extends StateNotifier<AsyncValue<void>> {
  MeetingNotifier() : super(const AsyncValue.data(null));

  Future<void> createMeeting({
    required String clubId,
    required String title,
    String? description,
    required String meetingType,
    String? locationName,
    String? virtualLink,
    required DateTime startsAt,
    required int durationMinutes,
  }) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.clubMeetings(clubId).add({
        'club_id': clubId,
        'title': title.trim(),
        'description': description?.trim(),
        'meeting_type': meetingType,
        'location_name': locationName?.trim(),
        'virtual_link': virtualLink?.trim(),
        'starts_at': startsAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'reminder_offsets': [1440, 60],
        'created_by': userId,
        'cancelled': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> submitRsvp({
    required String clubId,
    required String meetingId,
    required String status,
  }) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.meetingRsvps(clubId, meetingId)
          .doc(userId)
          .set({
        'user_id': userId,
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
}

final meetingNotifierProvider =
    StateNotifierProvider<MeetingNotifier, AsyncValue<void>>((ref) {
  return MeetingNotifier();
});
