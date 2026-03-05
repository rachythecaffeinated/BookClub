import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/home_providers.dart';

class ClubActivityCard extends ConsumerWidget {
  const ClubActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(clubActivitySummaryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Club Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            activityAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const Text('Unable to load clubs'),
              data: (summaries) {
                if (summaries.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(Icons.groups,
                            size: 32, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No active club reads',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/clubs'),
                          child: const Text('Join a Club'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: summaries
                      .map((s) => _ClubActivityTile(summary: s))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubActivityTile extends StatelessWidget {
  final ClubActivitySummary summary;

  const _ClubActivityTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.goNamed(
        RouteNames.clubHome,
        pathParameters: {'clubId': summary.club.id},
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Club name
            Text(
              summary.club.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            // Book info row
            if (summary.currentBook != null)
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 28,
                      height: 42,
                      child: summary.currentBook!.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: summary.currentBook!.coverUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppTheme.divider,
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppTheme.divider,
                                child: const Icon(Icons.book, size: 14),
                              ),
                            )
                          : Container(
                              color: AppTheme.divider,
                              child: const Icon(Icons.book, size: 14),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary.currentBook!.title,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            // Progress comparison
            _ProgressRow(
              label: 'You',
              value: summary.myProgress,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 4),
            _ProgressRow(
              label: 'Group',
              value: summary.groupAverage,
              color: AppTheme.primaryLight,
            ),
            // Next meeting
            if (summary.nextMeeting != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.event, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat.MMMd().add_jm().format(summary.nextMeeting!.startsAt),
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppTheme.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 32,
          child: Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
