import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/providers/home_providers.dart';

class StreakHeatmapCard extends ConsumerWidget {
  const StreakHeatmapCard({super.key});

  static const _heatmapColors = [
    Color(0xFFEDECFF), // 0: no reading
    Color(0xFFCBC8FF), // 1: 1-10 pages
    Color(0xFF9D97FF), // 2: 11-30 pages
    Color(0xFF6C63FF), // 3: 31-60 pages
    Color(0xFF4A42D4), // 4: 60+ pages
  ];

  static int _intensityLevel(int pages) {
    if (pages <= 0) return 0;
    if (pages <= 10) return 1;
    if (pages <= 30) return 2;
    if (pages <= 60) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyPagesAsync = ref.watch(dailyPagesProvider);
    final streakAsync = ref.watch(readingStreakProvider);

    return GestureDetector(
      onTap: () => context.go('/stats'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('🔥', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      streakAsync.when(
                        loading: () => const Text('-- day streak'),
                        error: (_, __) => const Text('0 day streak'),
                        data: (streak) => Text(
                          '${streak?.currentStreak ?? 0} day streak',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'View Stats',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 18, color: AppTheme.primary),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Heatmap grid
              dailyPagesAsync.when(
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox(
                  height: 100,
                  child: Center(child: Text('Unable to load activity')),
                ),
                data: (dailyPages) =>
                    _HeatmapGrid(dailyPages: dailyPages),
              ),
              const SizedBox(height: 12),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Less',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ..._heatmapColors.map((color) => Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),
                  const SizedBox(width: 4),
                  Text(
                    'More',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final Map<String, int> dailyPages;

  const _HeatmapGrid({required this.dailyPages});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 90));

    // Build 13 columns (weeks), 7 rows (Mon=0 to Sun=6).
    final columns = <List<_CellData>>[];
    var current = startDate;

    // Align to the start of the week (Monday).
    while (current.weekday != DateTime.monday) {
      current = current.subtract(const Duration(days: 1));
    }

    while (current.isBefore(today) ||
        current.isAtSameMomentAs(today) ||
        // Complete the current week.
        (columns.isNotEmpty && columns.last.length < 7)) {
      if (columns.isEmpty || columns.last.length >= 7) {
        columns.add([]);
      }

      final dateKey =
          '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      final pages = dailyPages[dateKey] ?? 0;
      final isFuture = current.isAfter(today);

      columns.last.add(_CellData(
        level: isFuture ? -1 : StreakHeatmapCard._intensityLevel(pages),
        date: current,
      ));

      current = current.add(const Duration(days: 1));
    }

    const cellSize = 12.0;
    const cellGap = 2.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns.map((week) {
          return Column(
            children: week.map((cell) {
              return Container(
                width: cellSize,
                height: cellSize,
                margin: const EdgeInsets.all(cellGap / 2),
                decoration: BoxDecoration(
                  color: cell.level < 0
                      ? Colors.transparent
                      : StreakHeatmapCard._heatmapColors[cell.level],
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _CellData {
  final int level; // -1 for future dates
  final DateTime date;

  const _CellData({required this.level, required this.date});
}
