import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          // Profile header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey[200],
                  child: profileAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) =>
                        Icon(Icons.person, size: 48, color: Colors.grey[400]),
                    data: (profile) {
                      if (profile?.avatarUrl != null) {
                        return ClipOval(
                          child: Image.network(
                            profile!.avatarUrl!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return Icon(Icons.person,
                          size: 48, color: Colors.grey[400]);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                profileAsync.when(
                  loading: () => const Text('Loading...'),
                  error: (_, __) => const Text('Error loading profile'),
                  data: (profile) => Text(
                    profile?.displayName ?? 'No name set',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Settings
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(RouteNames.profileSetup),
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Reading Goals'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(RouteNames.readingGoals),
          ),
          ListTile(
            leading: const Icon(Icons.local_fire_department),
            title: const Text('Streak Settings'),
            subtitle: const Text('Grace day, notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Streak settings screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Notification preferences screen
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[400]),
            title: Text('Log Out', style: TextStyle(color: Colors.red[400])),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
