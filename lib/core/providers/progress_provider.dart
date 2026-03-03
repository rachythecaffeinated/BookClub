import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reading_progress.dart';
import '../services/firebase_service.dart';

/// Provides all member progress for a given club.
final clubProgressProvider = FutureProvider.autoDispose
    .family<List<ReadingProgress>, String>((ref, clubId) async {
  final snapshot = await FirebaseService.clubProgress(clubId).get();

  final list = snapshot.docs
      .map((doc) => ReadingProgress.fromJson(
          FirebaseService.docToJson(doc, extra: {'club_id': clubId})))
      .toList();
  list.sort((a, b) => b.percentComplete.compareTo(a.percentComplete));
  return list;
});

/// Provides the current user's progress in a specific club.
final myProgressProvider = FutureProvider.autoDispose
    .family<ReadingProgress?, String>((ref, clubId) async {
  final userId = FirebaseService.currentUserId;
  if (userId == null) return null;

  final snapshot = await FirebaseService.clubProgress(clubId)
      .where('user_id', isEqualTo: userId)
      .limit(1)
      .get();

  if (snapshot.docs.isEmpty) return null;
  final doc = snapshot.docs.first;
  return ReadingProgress.fromJson(
      FirebaseService.docToJson(doc, extra: {'club_id': clubId}));
});

/// Progress update actions.
class ProgressNotifier extends StateNotifier<AsyncValue<void>> {
  ProgressNotifier() : super(const AsyncValue.data(null));

  Future<void> updateProgress({
    required String clubId,
    required String bookId,
    int? currentPage,
    int? currentLocation,
    int? currentTimestampSec,
    required double percentComplete,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      final progressDocId = '${userId}_$bookId';

      final data = {
        'user_id': userId,
        'club_id': clubId,
        'book_id': bookId,
        'current_page': currentPage,
        'current_location': currentLocation,
        'current_timestamp_sec': currentTimestampSec,
        'percent_complete': percentComplete,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Upsert via set with merge.
      await FirebaseService.clubProgress(clubId)
          .doc(progressDocId)
          .set(data, SetOptions(merge: true));

      // Append to progress_log for pace tracking.
      await FirebaseService.progressLog(userId).add({
        'book_id': bookId,
        'club_id': clubId,
        'current_page': currentPage,
        'current_location': currentLocation,
        'current_timestamp_sec': currentTimestampSec,
        'percent_complete': percentComplete,
        'logged_at': FieldValue.serverTimestamp(),
      });
    });
  }
}

final progressNotifierProvider =
    StateNotifierProvider<ProgressNotifier, AsyncValue<void>>((ref) {
  return ProgressNotifier();
});
