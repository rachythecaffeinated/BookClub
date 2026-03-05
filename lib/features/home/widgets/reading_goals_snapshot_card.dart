import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/models/reading_goal.dart';
import '../../../core/providers/home_providers.dart';

class ReadingGoalsSnapshotCard extends ConsumerWidget {
  const ReadingGoalsSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(goalProgressSnapshotProvider);

    return GestureDetector(
      onTap: () => context.go('/stats'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reading Goals',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              snapshotAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => const Text('Unable to load goals'),
                data: (snapshots) {
                  if (snapshots.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          Icon(Icons.flag_outlined,
                              size: 32, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No goals set',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                context.pushNamed(RouteNames.readingGoals),
                            child: const Text('Set a Reading Goal'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: snapshots.map((snapshot) {
                      final periodLabel = _periodLabel(snapshot);
                      final typeLabel = snapshot.goal.goalType.name;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _goalIcon(snapshot.goal.goalPeriod.name),
                                  size: 18,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$periodLabel: ${snapshot.currentValue}/${snapshot.goal.targetValue} $typeLabel',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: snapshot.progressFraction,
                                minHeight: 6,
                                backgroundColor: AppTheme.divider,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  snapshot.progressFraction >= 1.0
                                      ? AppTheme.success
                                      : AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _periodLabel(GoalSnapshot snapshot) {
    switch (snapshot.goal.goalPeriod) {
      case GoalPeriod.weekly:
        return 'This week';
      case GoalPeriod.monthly:
        return 'This month';
      case GoalPeriod.yearly:
        return 'This year';
    }
  }

  IconData _goalIcon(String period) {
    switch (period) {
      case 'weekly':
        return Icons.calendar_view_week;
      case 'monthly':
        return Icons.calendar_month;
      case 'yearly':
        return Icons.calendar_today;
      default:
        return Icons.flag;
    }
  }
}
