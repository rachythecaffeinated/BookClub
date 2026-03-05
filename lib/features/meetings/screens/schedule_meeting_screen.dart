import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/meeting_provider.dart';

class ScheduleMeetingScreen extends ConsumerStatefulWidget {
  final String clubId;

  const ScheduleMeetingScreen({super.key, required this.clubId});

  @override
  ConsumerState<ScheduleMeetingScreen> createState() =>
      _ScheduleMeetingScreenState();
}

class _ScheduleMeetingScreenState
    extends ConsumerState<ScheduleMeetingScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkController = TextEditingController();
  String _meetingType = 'in_person';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 15, minute: 0);
  int _durationMinutes = 60;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting title')),
      );
      return;
    }

    setState(() => _saving = true);

    final startsAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    await ref.read(meetingNotifierProvider.notifier).createMeeting(
          clubId: widget.clubId,
          title: title,
          description: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          meetingType: _meetingType,
          locationName:
              (_meetingType == 'in_person' || _meetingType == 'hybrid') &&
                      _locationController.text.trim().isNotEmpty
                  ? _locationController.text.trim()
                  : null,
          virtualLink:
              (_meetingType == 'virtual' || _meetingType == 'hybrid') &&
                      _linkController.text.trim().isNotEmpty
                  ? _linkController.text.trim()
                  : null,
          startsAt: startsAt,
          durationMinutes: _durationMinutes,
        );

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting scheduled!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Meeting')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Meeting Title',
              hintText: 'e.g., Dune Discussion Night',
            ),
          ),
          const SizedBox(height: 16),

          // Date & Time
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            subtitle: Text(
              '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Time'),
            subtitle: Text(_selectedTime.format(context)),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) setState(() => _selectedTime = time);
            },
          ),

          // Duration
          ListTile(
            leading: const Icon(Icons.timelapse),
            title: const Text('Duration'),
            subtitle: Text('$_durationMinutes minutes'),
            trailing: DropdownButton<int>(
              value: _durationMinutes,
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 min')),
                DropdownMenuItem(value: 60, child: Text('1 hr')),
                DropdownMenuItem(value: 90, child: Text('1.5 hr')),
                DropdownMenuItem(value: 120, child: Text('2 hr')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _durationMinutes = v);
              },
            ),
          ),
          const Divider(),

          // Meeting type
          Text('Meeting Type', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'in_person',
                label: Text('In Person'),
                icon: Icon(Icons.place),
              ),
              ButtonSegment(
                value: 'virtual',
                label: Text('Virtual'),
                icon: Icon(Icons.videocam),
              ),
              ButtonSegment(
                value: 'hybrid',
                label: Text('Hybrid'),
                icon: Icon(Icons.people),
              ),
            ],
            selected: {_meetingType},
            onSelectionChanged: (v) =>
                setState(() => _meetingType = v.first),
          ),
          const SizedBox(height: 16),

          if (_meetingType == 'in_person' || _meetingType == 'hybrid')
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Blue Bottle Coffee, 123 Main St',
                prefixIcon: Icon(Icons.place),
              ),
            ),
          if (_meetingType == 'virtual' || _meetingType == 'hybrid') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Virtual Link',
                hintText: 'Zoom, Discord, or Google Meet URL',
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ],
          const SizedBox(height: 16),

          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g., We\'ll discuss chapters 1-15',
            ),
            maxLines: 3,
            maxLength: AppConstants.meetingDescriptionMaxLength,
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Schedule Meeting'),
          ),
        ],
      ),
    );
  }
}
