import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../models/club.dart';
import '../models/club_meeting.dart';
import '../models/reading_goal.dart';
import '../models/reading_streak.dart';
import '../services/firebase_service.dart';
import 'meeting_provider.dart';
import 'personal_library_provider.dart';
import 'progress_provider.dart';
import 'reading_goals_provider.dart';

// ── Daily pages (heatmap data) ─────────────────────────────────────

/// Aggregates progressLog entries into daily page counts for the last 91 days.
/// Returns Map<String, int> where key is 'yyyy-MM-dd' and value is pages read.
final dailyPagesProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final userId = FirebaseService.currentUserId;
  if (userId == null) return {};

  final cutoff = DateTime.now().subtract(const Duration(days: 91));
  final snapshot = await FirebaseService.progressLog(userId)
      .where('logged_at', isGreaterThan: Timestamp.fromDate(cutoff))
      .orderBy('logged_at')
      .get();

  final Map<String, int> lastPageByBook = {};
  final Map<String, int> dailyTotals = {};

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final bookId = data['book_id'] as String?;
    final page = data['current_page'] as int?;
    if (bookId == null || page == null) continue;

    final loggedAt = data['logged_at'];
    if (loggedAt == null) continue;
    final date = (loggedAt as Timestamp).toDate();
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final lastPage = lastPageByBook[bookId] ?? 0;
    final delta = (page - lastPage).clamp(0, page);

    if (delta > 0) {
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + delta;
    }
    lastPageByBook[bookId] = page;
  }

  return dailyTotals;
});

// ── Reading streak ─────────────────────────────────────────────────

/// Fetches the user's reading streak document.
final readingStreakProvider =
    FutureProvider.autoDispose<ReadingStreak?>((ref) async {
  final userId = FirebaseService.currentUserId;
  if (userId == null) return null;

  final doc = await FirebaseService.readingStreaks(userId).get();
  if (!doc.exists || doc.data() == null) return null;
  return ReadingStreak.fromJson(
    FirebaseService.docToJson(doc, extra: {'user_id': userId}),
  );
});

// ── Club activity summary ──────────────────────────────────────────

class ClubActivitySummary {
  final Club club;
  final Book? currentBook;
  final double myProgress;
  final double groupAverage;
  final ClubMeeting? nextMeeting;

  const ClubActivitySummary({
    required this.club,
    this.currentBook,
    this.myProgress = 0.0,
    this.groupAverage = 0.0,
    this.nextMeeting,
  });
}

/// Provides a summary of each club's activity for the home screen.
final clubActivitySummaryProvider =
    FutureProvider.autoDispose<List<ClubActivitySummary>>((ref) async {
  final clubBooks = await ref.watch(clubCurrentBooksProvider.future);

  final results = <ClubActivitySummary>[];
  for (final cb in clubBooks) {
    final allProgress =
        await ref.watch(clubProgressProvider(cb.club.id).future);
    final avgPercent = allProgress.isEmpty
        ? 0.0
        : allProgress.fold<double>(
                0, (acc, p) => acc + p.percentComplete) /
            allProgress.length;

    ClubMeeting? meeting;
    try {
      meeting = await ref.watch(nextMeetingProvider(cb.club.id).future);
    } catch (_) {
      // No meeting found is fine.
    }

    results.add(ClubActivitySummary(
      club: cb.club,
      currentBook: cb.book,
      myProgress: (cb.myProgress?.percentComplete ?? 0.0) / 100.0,
      groupAverage: avgPercent / 100.0,
      nextMeeting: meeting,
    ));
  }
  return results;
});

// ── Goal progress snapshot ─────────────────────────────────────────

class GoalSnapshot {
  final ReadingGoal goal;
  final int currentValue;

  const GoalSnapshot({required this.goal, required this.currentValue});

  double get progressFraction => goal.targetValue > 0
      ? (currentValue / goal.targetValue).clamp(0.0, 1.0)
      : 0.0;
}

/// Pairs each active ReadingGoal with its current progress.
final goalProgressSnapshotProvider =
    FutureProvider.autoDispose<List<GoalSnapshot>>((ref) async {
  final goals = await ref.watch(readingGoalsProvider.future);
  final activeGoals = goals.where((g) => g.isActive).toList();
  if (activeGoals.isEmpty) return [];

  final dailyPages = await ref.watch(dailyPagesProvider.future);

  return activeGoals.map((goal) {
    final range = _periodRange(goal.goalPeriod);
    int total = 0;
    for (final entry in dailyPages.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      if (!date.isBefore(range.start) && date.isBefore(range.end)) {
        total += entry.value;
      }
    }
    return GoalSnapshot(goal: goal, currentValue: total);
  }).toList();
});

/// Returns the date range for a goal period (start inclusive, end exclusive).
({DateTime start, DateTime end}) _periodRange(GoalPeriod period) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  switch (period) {
    case GoalPeriod.weekly:
      // Week starts on Monday.
      final weekday = today.weekday; // 1 = Monday
      final start = today.subtract(Duration(days: weekday - 1));
      final end = start.add(const Duration(days: 7));
      return (start: start, end: end);
    case GoalPeriod.monthly:
      final start = DateTime(now.year, now.month);
      final end = DateTime(now.year, now.month + 1);
      return (start: start, end: end);
    case GoalPeriod.yearly:
      final start = DateTime(now.year);
      final end = DateTime(now.year + 1);
      return (start: start, end: end);
  }
}
