import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/meeting_provider.dart';

class MeetingDetailScreen extends ConsumerWidget {
  final String clubId;
  final String meetingId;

  const MeetingDetailScreen({
    super.key,
    required this.clubId,
    required this.meetingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingAsync = ref.watch(
      meetingDetailProvider((clubId: clubId, meetingId: meetingId)),
    );
    final rsvpAsync = ref.watch(
      myRsvpProvider((clubId: clubId, meetingId: meetingId)),
    );
    final currentRsvp = rsvpAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Meeting Details')),
      body: meetingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (meeting) {
          if (meeting == null) {
            return const Center(child: Text('Meeting not found'));
          }

          final dateFormat = DateFormat('EEEE, MMM d, y');
          final timeFormat = DateFormat('h:mm a');
          final dateStr = dateFormat.format(meeting.startsAt);
          final timeStr = timeFormat.format(meeting.startsAt);

          String? locationText;
          if (meeting.locationName != null) {
            locationText = meeting.locationName;
          } else if (meeting.virtualLink != null) {
            locationText = meeting.virtualLink;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Meeting header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '$dateStr at $timeStr',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.timelapse, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${meeting.durationMinutes} minutes',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (locationText != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              meeting.virtualLink != null
                                  ? Icons.link
                                  : Icons.place,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                locationText,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (meeting.description != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          meeting.description!,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // RSVP buttons
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RSVP',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _RsvpButton(
                            label: 'Going',
                            icon: Icons.check_circle,
                            color: Colors.green,
                            isSelected: currentRsvp == 'going',
                            onTap: () => _submitRsvp(ref, 'going'),
                          ),
                          _RsvpButton(
                            label: 'Maybe',
                            icon: Icons.help,
                            color: Colors.orange,
                            isSelected: currentRsvp == 'maybe',
                            onTap: () => _submitRsvp(ref, 'maybe'),
                          ),
                          _RsvpButton(
                            label: "Can't",
                            icon: Icons.cancel,
                            color: Colors.red,
                            isSelected: currentRsvp == 'cant',
                            onTap: () => _submitRsvp(ref, 'cant'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Add to calendar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final event = Event(
                      title: meeting.title,
                      description: meeting.description ?? '',
                      location:
                          meeting.locationName ?? meeting.virtualLink ?? '',
                      startDate: meeting.startsAt,
                      endDate: meeting.startsAt.add(
                        Duration(minutes: meeting.durationMinutes),
                      ),
                    );
                    Add2Calendar.addEvent2Cal(event);
                  },
                  icon: const Icon(Icons.event),
                  label: const Text('Add to Calendar'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submitRsvp(WidgetRef ref, String status) {
    ref.read(meetingNotifierProvider.notifier).submitRsvp(
          clubId: clubId,
          meetingId: meetingId,
          status: status,
        );
    ref.invalidate(
      myRsvpProvider((clubId: clubId, meetingId: meetingId)),
    );
  }
}

class _RsvpButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RsvpButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 2),
              )
            : null,
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
