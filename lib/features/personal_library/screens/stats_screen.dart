import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/providers/home_providers.dart';
import '../../../shared/widgets/screen_header.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyPagesAsync = ref.watch(dailyPagesProvider);
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM').format(now).toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ScreenHeader(
              sectionLabel: '$monthLabel ACTIVITY',
              titlePrefix: 'Insights ',
              titleAccent: '& Data',
            ),

            // ── Yearly Consistency Heatmap ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'YEARLY CONSISTENCY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    dailyPagesAsync.when(
                      loading: () => const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox(
                        height: 100,
                        child: Center(child: Text('Unable to load')),
                      ),
                      data: (dailyPages) =>
                          _YearlyHeatmap(dailyPages: dailyPages),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Stat Cards Row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: dailyPagesAsync.when(
                loading: () => const SizedBox(height: 100),
                error: (_, __) => const SizedBox(height: 100),
                data: (dailyPages) {
                  int totalPages = 0;
                  for (final v in dailyPages.values) {
                    totalPages += v;
                  }
                  return Row(
                    children: [
                      // Total Pages (purple bg)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.schedule,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 20),
                              const SizedBox(height: 8),
                              Text(
                                '${_formatNumber(totalPages)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'TOTAL PAGES',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Reader Rank (white bg, placeholder)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.directions_run,
                                  color: AppTheme.textSecondary, size: 20),
                              const SizedBox(height: 8),
                              const Text(
                                'Top 3%',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'READER RANK',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Weekly Velocity ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: dailyPagesAsync.when(
                loading: () => const SizedBox(height: 200),
                error: (_, __) => const SizedBox(height: 200),
                data: (dailyPages) =>
                    _WeeklyVelocityCard(dailyPages: dailyPages),
              ),
            ),
            const SizedBox(height: 16),

            // ── Focus Time (placeholder) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FOCUS TIME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InsightCard(
                    icon: Icons.nightlight_round,
                    iconColor: Colors.orange,
                    title: 'Late Night Owl',
                    subtitle: '65% of reading happens after 10 PM',
                  ),
                  const SizedBox(height: 8),
                  _InsightCard(
                    icon: Icons.bolt,
                    iconColor: AppTheme.primary,
                    title: 'Hyper Focus',
                    subtitle: 'Longest session today: 48 minutes',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return '$n';
  }
}

// ── Yearly Heatmap (90-day, GitHub-style, with month labels) ─────────

class _YearlyHeatmap extends StatelessWidget {
  final Map<String, int> dailyPages;

  const _YearlyHeatmap({required this.dailyPages});

  static const _colors = [
    Color(0xFFEDECFF),
    Color(0xFFCBC8FF),
    Color(0xFF9D97FF),
    Color(0xFF7B73D0),
    Color(0xFF6C63FF),
  ];

  int _level(int pages) {
    if (pages <= 0) return 0;
    if (pages <= 10) return 1;
    if (pages <= 30) return 2;
    if (pages <= 60) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 90));

    // Align to Monday
    var current = startDate;
    while (current.weekday != DateTime.monday) {
      current = current.subtract(const Duration(days: 1));
    }

    final columns = <List<_DayData>>[];
    while (current.isBefore(today) ||
        current.isAtSameMomentAs(today) ||
        (columns.isNotEmpty && columns.last.length < 7)) {
      if (columns.isEmpty || columns.last.length >= 7) {
        columns.add([]);
      }

      final dateKey =
          '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      final pages = dailyPages[dateKey] ?? 0;
      final isFuture = current.isAfter(today);

      columns.last.add(_DayData(
        level: isFuture ? -1 : _level(pages),
        date: current,
      ));

      current = current.add(const Duration(days: 1));
    }

    // Find month labels
    final monthLabels = <int, String>{};
    for (int i = 0; i < columns.length; i++) {
      final firstDay = columns[i].first.date;
      if (firstDay.day <= 7 && !monthLabels.containsValue(
          DateFormat('MMM').format(firstDay).toUpperCase())) {
        monthLabels[i] = DateFormat('MMM').format(firstDay).toUpperCase();
      }
    }

    const cellSize = 11.0;
    const gap = 2.0;

    return Column(
      children: [
        SizedBox(
          height: 7 * (cellSize + gap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns.asMap().entries.map((entry) {
              return Column(
                children: entry.value.map((day) {
                  return Container(
                    width: cellSize,
                    height: cellSize,
                    margin: const EdgeInsets.all(gap / 2),
                    decoration: BoxDecoration(
                      color: day.level < 0
                          ? Colors.transparent
                          : _colors[day.level],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        // Month labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: monthLabels.values
              .map((label) => Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _DayData {
  final int level;
  final DateTime date;
  const _DayData({required this.level, required this.date});
}

// ── Weekly Velocity Card ─────────────────────────────────────────────

class _WeeklyVelocityCard extends StatelessWidget {
  final Map<String, int> dailyPages;

  const _WeeklyVelocityCard({required this.dailyPages});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Get this week's data (Mon-Sun)
    final weekday = today.weekday;
    final monday = today.subtract(Duration(days: weekday - 1));

    final weekData = <int>[];
    int weekTotal = 0;
    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final pages = dailyPages[dateKey] ?? 0;
      weekData.add(pages);
      weekTotal += pages;
    }

    final daysWithData = weekData.where((p) => p > 0).length;
    final dailyAvg = daysWithData > 0 ? (weekTotal / daysWithData).round() : 0;
    final maxPages = weekData.reduce((a, b) => a > b ? a : b);

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Velocity',
                    style: TextStyle(
                      color: AppTheme.textOnDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Daily average: $dailyAvg pages',
                    style: TextStyle(
                      color: AppTheme.textOnDark.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+12% vs LW',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bar chart
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxPages > 0 ? maxPages.toDouble() : 50) * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dayLabels[idx],
                            style: TextStyle(
                              color:
                                  AppTheme.textOnDark.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final isToday = i == (today.weekday - 1);
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: weekData[i].toDouble(),
                        color: isToday
                            ? AppTheme.primary
                            : AppTheme.primaryLight.withValues(alpha: 0.3),
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Insight Card ─────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
