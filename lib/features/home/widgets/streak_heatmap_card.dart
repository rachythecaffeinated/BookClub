import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/providers/home_providers.dart';

class StreakHeatmapCard extends ConsumerWidget {
  const StreakHeatmapCard({super.key});

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
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now).toUpperCase();

    return GestureDetector(
      onTap: () => context.go('/stats'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: streak info + month + total pages
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: fire + streak
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          streakAsync.when(
                            loading: () => const Text(
                              '-- Day Streak',
                              style: TextStyle(
                                color: AppTheme.textOnDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            error: (_, __) => const Text(
                              '0 Day Streak',
                              style: TextStyle(
                                color: AppTheme.textOnDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            data: (streak) => Text(
                              '${streak?.currentStreak ?? 0} Day Streak',
                              style: const TextStyle(
                                color: AppTheme.textOnDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      streakAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (streak) => Text(
                          'Personal Best: ${streak?.longestStreak ?? 0} days',
                          style: TextStyle(
                            color: AppTheme.textOnDark.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right: month + total pages
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      monthName,
                      style: TextStyle(
                        color: AppTheme.textOnDark.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    dailyPagesAsync.when(
                      loading: () => const Text(
                        '-- pgs',
                        style: TextStyle(
                          color: AppTheme.textOnDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      error: (_, __) => const Text(
                        '0 pgs',
                        style: TextStyle(
                          color: AppTheme.textOnDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      data: (dailyPages) {
                        final monthTotal = _monthTotal(dailyPages, now);
                        return RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$monthTotal',
                                style: const TextStyle(
                                  color: AppTheme.textOnDark,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: ' pgs',
                                style: TextStyle(
                                  color: AppTheme.textOnDark
                                      .withValues(alpha: 0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Monthly calendar grid
            dailyPagesAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryLight),
                ),
              ),
              error: (_, __) => SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Unable to load activity',
                    style: TextStyle(
                      color: AppTheme.textOnDark.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              data: (dailyPages) => _MonthlyCalendarGrid(
                dailyPages: dailyPages,
                month: now,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _monthTotal(Map<String, int> dailyPages, DateTime now) {
    int total = 0;
    for (final entry in dailyPages.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date != null && date.year == now.year && date.month == now.month) {
        total += entry.value;
      }
    }
    return total;
  }
}

class _MonthlyCalendarGrid extends StatelessWidget {
  final Map<String, int> dailyPages;
  final DateTime month;

  const _MonthlyCalendarGrid({
    required this.dailyPages,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final year = month.year;
    final mon = month.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, mon);
    final firstDay = DateTime(year, mon, 1);
    // Monday = 1, so offset = (weekday - 1)
    final startOffset = firstDay.weekday - 1;
    final today = DateTime.now();

    // Day-of-week headers
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        // Day-of-week row
        Row(
          children: dayLabels
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          color: AppTheme.textOnDark.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        // Calendar rows
        ..._buildWeeks(daysInMonth, startOffset, today),
      ],
    );
  }

  List<Widget> _buildWeeks(int daysInMonth, int startOffset, DateTime today) {
    final weeks = <Widget>[];
    int dayCounter = 1;

    // Calculate total cells needed
    final totalCells = startOffset + daysInMonth;
    final numWeeks = (totalCells / 7).ceil();

    for (int week = 0; week < numWeeks; week++) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        final cellIndex = week * 7 + col;
        if (cellIndex < startOffset || dayCounter > daysInMonth) {
          // Empty cell
          cells.add(const Expanded(child: SizedBox(height: 38)));
        } else {
          final day = dayCounter;
          final date = DateTime(month.year, month.month, day);
          final dateKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final pages = dailyPages[dateKey] ?? 0;
          final isFuture = date.isAfter(today);
          final level =
              isFuture ? -1 : StreakHeatmapCard._intensityLevel(pages);

          cells.add(Expanded(
            child: _CalendarCell(
              day: day,
              pages: pages,
              level: level,
              isFuture: isFuture,
            ),
          ));
          dayCounter++;
        }
      }
      weeks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: cells),
        ),
      );
    }
    return weeks;
  }
}

class _CalendarCell extends StatelessWidget {
  final int day;
  final int pages;
  final int level; // -1 for future
  final bool isFuture;

  const _CalendarCell({
    required this.day,
    required this.pages,
    required this.level,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isFuture
        ? Colors.transparent
        : level >= 0
            ? AppTheme.streakColors[level]
            : Colors.transparent;

    return Container(
      height: 38,
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: isFuture
          ? Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: AppTheme.textOnDark.withValues(alpha: 0.15),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: AppTheme.textOnDark.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (pages > 0)
                  Text(
                    '$pages',
                    style: TextStyle(
                      color: AppTheme.textOnDark.withValues(alpha: 0.5),
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
    );
  }
}
