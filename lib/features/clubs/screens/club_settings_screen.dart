import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/club_provider.dart';
import '../../../core/providers/progress_provider.dart';

class ClubSettingsScreen extends ConsumerWidget {
  final String clubId;

  const ClubSettingsScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Club Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Club Name & Description'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to edit club screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Change Club Avatar'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Pick avatar
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Change Current Book'),
            subtitle: const Text('Clears current book and resets all progress'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmChangeBook(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red[400]),
            title: Text('Delete Club',
                style: TextStyle(color: Colors.red[400])),
            onTap: () {
              // TODO: Confirm and delete
            },
          ),
        ],
      ),
    );
  }

  void _confirmChangeBook(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Current Book?'),
        content: const Text(
          'This will clear the current book and reset all member progress. '
          'You can then choose a new book.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(clubNotifierProvider.notifier)
                  .clearCurrentBook(clubId: clubId);
              ref.invalidate(clubProvider(clubId));
              ref.invalidate(currentBookProvider(clubId));
              ref.invalidate(clubProgressProvider(clubId));
              ref.invalidate(myProgressProvider(clubId));
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text('Clear Book'),
          ),
        ],
      ),
    );
  }
}
