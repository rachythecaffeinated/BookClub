import 'package:equatable/equatable.dart';

class ReadingStreak extends Equatable {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastReadDate;
  final bool graceDayEnabled;
  final bool graceDayUsedThisWeek;
  final DateTime? streakStartedAt;

  const ReadingStreak({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastReadDate,
    this.graceDayEnabled = false,
    this.graceDayUsedThisWeek = false,
    this.streakStartedAt,
  });

  factory ReadingStreak.fromJson(Map<String, dynamic> json) {
    return ReadingStreak(
      userId: json['user_id'] as String,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastReadDate: json['last_read_date'] != null
          ? DateTime.parse(json['last_read_date'] as String)
          : null,
      graceDayEnabled: json['grace_day_enabled'] as bool? ?? false,
      graceDayUsedThisWeek:
          json['grace_day_used_this_week'] as bool? ?? false,
      streakStartedAt: json['streak_started_at'] != null
          ? DateTime.parse(json['streak_started_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_read_date': lastReadDate?.toIso8601String().split('T').first,
      'grace_day_enabled': graceDayEnabled,
      'grace_day_used_this_week': graceDayUsedThisWeek,
      'streak_started_at':
          streakStartedAt?.toIso8601String().split('T').first,
    };
  }

  String get milestoneLabel {
    if (currentStreak >= 365) return 'Year-round reader';
    if (currentStreak >= 100) return 'Century club';
    if (currentStreak >= 30) return 'Monthly reader';
    if (currentStreak >= 7) return 'One week strong';
    return '';
  }

  @override
  List<Object?> get props => [userId, currentStreak, longestStreak];
}
