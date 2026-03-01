import 'package:equatable/equatable.dart';

enum GoalPeriod { weekly, monthly, yearly }

enum GoalType { pages, minutes, books }

class ReadingGoal extends Equatable {
  final String id;
  final String userId;
  final GoalPeriod goalPeriod;
  final GoalType goalType;
  final int targetValue;
  final String? weekStartDay;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReadingGoal({
    required this.id,
    required this.userId,
    required this.goalPeriod,
    required this.goalType,
    required this.targetValue,
    this.weekStartDay = 'MO',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReadingGoal.fromJson(Map<String, dynamic> json) {
    return ReadingGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalPeriod: GoalPeriod.values.firstWhere(
        (g) => g.name == json['goal_period'],
      ),
      goalType: GoalType.values.firstWhere(
        (g) => g.name == json['goal_type'],
      ),
      targetValue: json['target_value'] as int,
      weekStartDay: json['week_start_day'] as String? ?? 'MO',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'goal_period': goalPeriod.name,
      'goal_type': goalType.name,
      'target_value': targetValue,
      'week_start_day': weekStartDay,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [id, goalPeriod, goalType, targetValue, isActive];
}
