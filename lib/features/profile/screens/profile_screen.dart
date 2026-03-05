import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/screen_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const ScreenHeader(
              sectionLabel: 'ACCOUNT SETTINGS',
              titlePrefix: 'My ',
              titleAccent: 'Profile',
            ),

            // Avatar + Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Avatar
                  profileAsync.when(
                    loading: () => const CircleAvatar(
                      radius: 52,
                      backgroundColor: AppTheme.divider,
                      child: CircularProgressIndicator(),
                    ),
                    error: (_, __) => CircleAvatar(
                      radius: 52,
                      backgroundColor: AppTheme.divider,
                      child: Icon(Icons.person,
                          size: 48, color: Colors.grey[400]),
                    ),
                    data: (profile) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.divider,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: AppTheme.divider,
                          backgroundImage: profile?.avatarUrl != null
                              ? NetworkImage(profile!.avatarUrl!)
                              : null,
                          child: profile?.avatarUrl == null
                              ? Icon(Icons.person,
                                  size: 48, color: Colors.grey[400])
                              : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Name
                  profileAsync.when(
                    loading: () => const Text('Loading...'),
                    error: (_, __) => const Text('Error loading profile'),
                    data: (profile) => Column(
                      children: [
                        Text(
                          profile?.displayName ?? 'No name set',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bibliophile since 2018',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Menu cards
                  _ProfileMenuCard(
                    icon: Icons.settings_outlined,
                    title: 'Account Settings',
                    trailing: const Icon(Icons.chevron_right,
                        color: AppTheme.textSecondary, size: 20),
                    onTap: () => context.pushNamed(RouteNames.profileSetup),
                  ),
                  const SizedBox(height: 8),
                  _ProfileMenuCard(
                    icon: Icons.emoji_events_outlined,
                    title: 'Achievements',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '12 NEW',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    onTap: () => context.pushNamed(RouteNames.readingGoals),
                  ),
                  const SizedBox(height: 8),
                  _ProfileMenuCard(
                    icon: Icons.cloud_outlined,
                    title: 'Cloud Backup',
                    trailing: Switch(
                      value: false,
                      onChanged: (_) {},
                      activeColor: AppTheme.primary,
                    ),
                    onTap: null,
                  ),
                  const SizedBox(height: 24),

                  // Log Out
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Log Out'),
                            content:
                                const Text('Are you sure you want to log out?'),
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
                          await ref
                              .read(authNotifierProvider.notifier)
                              .signOut();
                          if (context.mounted) {
                            context.go('/');
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(
                            color: AppTheme.error.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Log Out'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _ProfileMenuCard({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.textSecondary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
