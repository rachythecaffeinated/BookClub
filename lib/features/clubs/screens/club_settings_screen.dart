import 'package:flutter/material.dart';

class ClubSettingsScreen extends StatelessWidget {
  final String clubId;

  const ClubSettingsScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context) {
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
            subtitle: const Text('Resets all progress'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to scan/search book
            },
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
}
