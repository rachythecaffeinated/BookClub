import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  FirebaseService._();

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;

  static String? get currentUserId => auth.currentUser?.uid;
  static bool get isAuthenticated => auth.currentUser != null;

  // ── Top-level collections ──────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> get users =>
      firestore.collection('users');

  static CollectionReference<Map<String, dynamic>> get books =>
      firestore.collection('books');

  static CollectionReference<Map<String, dynamic>> get clubs =>
      firestore.collection('clubs');

  static CollectionReference<Map<String, dynamic>> get invites =>
      firestore.collection('invites');

  // ── Club subcollections ────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> clubMembers(
          String clubId) =>
      clubs.doc(clubId).collection('members');

  static CollectionReference<Map<String, dynamic>> clubBooks(String clubId) =>
      clubs.doc(clubId).collection('books');

  static CollectionReference<Map<String, dynamic>> clubProgress(
          String clubId) =>
      clubs.doc(clubId).collection('progress');

  static CollectionReference<Map<String, dynamic>> clubMessages(
          String clubId) =>
      clubs.doc(clubId).collection('messages');

  static CollectionReference<Map<String, dynamic>> clubNotes(String clubId) =>
      clubs.doc(clubId).collection('notes');

  static CollectionReference<Map<String, dynamic>> clubMeetings(
          String clubId) =>
      clubs.doc(clubId).collection('meetings');

  static CollectionReference<Map<String, dynamic>> bookPicks(String clubId) =>
      clubs.doc(clubId).collection('bookPicks');

  static CollectionReference<Map<String, dynamic>> clubReadReceipts(
          String clubId) =>
      clubs.doc(clubId).collection('readReceipts');

  static CollectionReference<Map<String, dynamic>> clubTyping(
          String clubId) =>
      clubs.doc(clubId).collection('typing');

  // ── Nested subcollections ──────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> meetingRsvps(
          String clubId, String meetingId) =>
      clubMeetings(clubId).doc(meetingId).collection('rsvps');

  static CollectionReference<Map<String, dynamic>> noteReactions(
          String clubId, String noteId) =>
      clubNotes(clubId).doc(noteId).collection('reactions');

  static CollectionReference<Map<String, dynamic>> noteReplies(
          String clubId, String noteId) =>
      clubNotes(clubId).doc(noteId).collection('replies');

  static CollectionReference<Map<String, dynamic>> bookPickProposals(
          String clubId, String bookPickId) =>
      bookPicks(clubId).doc(bookPickId).collection('proposals');

  static CollectionReference<Map<String, dynamic>> bookPickRatings(
          String clubId, String bookPickId) =>
      bookPicks(clubId).doc(bookPickId).collection('ratings');

  static CollectionReference<Map<String, dynamic>> bookPickParticipants(
          String clubId, String bookPickId) =>
      bookPicks(clubId).doc(bookPickId).collection('participants');

  // ── User subcollections ────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> personalBooks(
          String userId) =>
      users.doc(userId).collection('personalBooks');

  static CollectionReference<Map<String, dynamic>> dailyReadingLog(
          String userId) =>
      users.doc(userId).collection('dailyReadingLog');

  static CollectionReference<Map<String, dynamic>> readingGoals(
          String userId) =>
      users.doc(userId).collection('readingGoals');

  static CollectionReference<Map<String, dynamic>> goalProgress(
          String userId) =>
      users.doc(userId).collection('goalProgress');

  static CollectionReference<Map<String, dynamic>> progressLog(
          String userId) =>
      users.doc(userId).collection('progressLog');

  static DocumentReference<Map<String, dynamic>> readingStreaks(
          String userId) =>
      users.doc(userId).collection('streaks').doc('current');

  static DocumentReference<Map<String, dynamic>> chatReadReceipt(
          String clubId, String userId) =>
      clubReadReceipts(clubId).doc(userId);

  // ── Helpers ────────────────────────────────────────────────────────

  /// Convert a Firestore document snapshot to a JSON map suitable for model
  /// `fromJson` factories. Injects the document ID as `'id'` and converts
  /// Firestore [Timestamp] values to ISO 8601 strings so existing model
  /// parsing code works unchanged.
  ///
  /// Pass [extra] to inject additional fields that are implicit from the
  /// subcollection path (e.g. `{'club_id': clubId}`).
  static Map<String, dynamic> docToJson(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    Map<String, dynamic>? extra,
  }) {
    final data = doc.data();
    if (data == null) return {};
    return _normalizeTimestamps({
      'id': doc.id,
      if (extra != null) ...extra,
      ...data,
    });
  }

  static Map<String, dynamic> _normalizeTimestamps(
      Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      }
      return MapEntry(key, value);
    });
  }
}
