import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/providers/reading_goals_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(readingGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Reading Goals',
            onPressed: () => context.pushNamed(RouteNames.readingGoals),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Streak card (placeholder — streak calculation not yet implemented)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('0',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day Streak',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Longest: 0 days',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Active goals — wired to real data
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Goals',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  goalsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (goals) {
                      final active =
                          goals.where((g) => g.isActive).toList();
                      if (active.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              Icon(Icons.flag_outlined,
                                  size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'No goals set',
                                style:
                                    TextStyle(color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => context
                                    .pushNamed(RouteNames.readingGoals),
                                child:
                                    const Text('Set a Reading Goal'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: active.map((goal) {
                          final periodLabel = goal.goalPeriod.name[0]
                                  .toUpperCase() +
                              goal.goalPeriod.name.substring(1);
                          final typeLabel =
                              goal.goalType.name;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              _goalIcon(goal.goalPeriod.name),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            ),
                            title: Text(
                                '$periodLabel: ${goal.targetValue} $typeLabel'),
                            dense: true,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reading heatmap placeholder
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reading Activity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Coming soon',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Summary cards (placeholder — aggregation requires cross-club queries)
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'This Week',
                  value: '--',
                  unit: 'pages',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'This Month',
                  value: '--',
                  unit: 'pages',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'This Year',
                  value: '--',
                  unit: 'books',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Average pace
          Card(
            child: ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Average Pace'),
              subtitle: const Text('Coming soon'),
              trailing: Text(
                '30-day avg',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;

  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
