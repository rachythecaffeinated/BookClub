import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reading_progress.dart';
import '../services/supabase_service.dart';

/// Provides all member progress for a given club.
final clubProgressProvider = FutureProvider.autoDispose
    .family<List<ReadingProgress>, String>((ref, clubId) async {
  final response = await SupabaseService.readingProgress
      .select()
      .eq('club_id', clubId)
      .order('percent_complete', ascending: false);

  return (response as List)
      .map((row) => ReadingProgress.fromJson(row))
      .toList();
});

/// Provides the current user's progress in a specific club.
final myProgressProvider = FutureProvider.autoDispose
    .family<ReadingProgress?, String>((ref, clubId) async {
  final userId = SupabaseService.currentUserId;
  if (userId == null) return null;

  final response = await SupabaseService.readingProgress
      .select()
      .eq('user_id', userId)
      .eq('club_id', clubId)
      .maybeSingle();

  if (response == null) return null;
  return ReadingProgress.fromJson(response);
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
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      final data = {
        'user_id': userId,
        'club_id': clubId,
        'book_id': bookId,
        'current_page': currentPage,
        'current_location': currentLocation,
        'current_timestamp_sec': currentTimestampSec,
        'percent_complete': percentComplete,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Upsert the reading_progress row
      await SupabaseService.readingProgress.upsert(
        data,
        onConflict: 'user_id,club_id,book_id',
      );

      // Append to progress_log for pace tracking
      await SupabaseService.progressLog.insert({
        'user_id': userId,
        'book_id': bookId,
        'club_id': clubId,
        'current_page': currentPage,
        'current_location': currentLocation,
        'current_timestamp_sec': currentTimestampSec,
        'percent_complete': percentComplete,
      });
    });
  }
}

final progressNotifierProvider =
    StateNotifierProvider<ProgressNotifier, AsyncValue<void>>((ref) {
  return ProgressNotifier();
});
