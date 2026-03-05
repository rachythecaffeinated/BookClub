import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reading_goal.dart';
import '../services/firebase_service.dart';

/// Fetches all reading goals for the current user.
final readingGoalsProvider =
    FutureProvider.autoDispose<List<ReadingGoal>>((ref) async {
  final userId = FirebaseService.currentUserId;
  if (userId == null) return [];

  final snapshot = await FirebaseService.readingGoals(userId).get();
  return snapshot.docs
      .map((doc) => ReadingGoal.fromJson(
            FirebaseService.docToJson(doc, extra: {'user_id': userId}),
          ))
      .toList();
});

/// Notifier for saving reading goals.
class ReadingGoalsNotifier extends StateNotifier<AsyncValue<void>> {
  ReadingGoalsNotifier() : super(const AsyncValue.data(null));

  /// Saves reading goals. Uses the goal period as the doc ID for idempotent upserts.
  Future<void> saveGoals({
    required bool weeklyEnabled,
    required int? weeklyTarget,
    required bool monthlyEnabled,
    required int? monthlyTarget,
    required bool yearlyEnabled,
    required int? yearlyTarget,
  }) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final batch = FirebaseService.firestore.batch();
      final now = DateTime.now().toIso8601String();
      final goalsRef = FirebaseService.readingGoals(userId);

      if (weeklyEnabled && weeklyTarget != null && weeklyTarget > 0) {
        batch.set(
          goalsRef.doc('weekly'),
          {
            'user_id': userId,
            'goal_period': 'weekly',
            'goal_type': 'pages',
            'target_value': weeklyTarget,
            'is_active': true,
            'updated_at': now,
            'created_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        batch.set(
          goalsRef.doc('weekly'),
          {'is_active': false, 'updated_at': now},
          SetOptions(merge: true),
        );
      }

      if (monthlyEnabled && monthlyTarget != null && monthlyTarget > 0) {
        batch.set(
          goalsRef.doc('monthly'),
          {
            'user_id': userId,
            'goal_period': 'monthly',
            'goal_type': 'pages',
            'target_value': monthlyTarget,
            'is_active': true,
            'updated_at': now,
            'created_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        batch.set(
          goalsRef.doc('monthly'),
          {'is_active': false, 'updated_at': now},
          SetOptions(merge: true),
        );
      }

      if (yearlyEnabled && yearlyTarget != null && yearlyTarget > 0) {
        batch.set(
          goalsRef.doc('yearly'),
          {
            'user_id': userId,
            'goal_period': 'yearly',
            'goal_type': 'books',
            'target_value': yearlyTarget,
            'is_active': true,
            'updated_at': now,
            'created_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        batch.set(
          goalsRef.doc('yearly'),
          {'is_active': false, 'updated_at': now},
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    });
  }
}

final readingGoalsNotifierProvider =
    StateNotifierProvider<ReadingGoalsNotifier, AsyncValue<void>>((ref) {
  return ReadingGoalsNotifier();
});
