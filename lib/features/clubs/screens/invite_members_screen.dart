import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/club_provider.dart';

class InviteMembersScreen extends ConsumerWidget {
  final String clubId;

  const InviteMembersScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(clubProvider(clubId));
    final membersAsync = ref.watch(clubMembersProvider(clubId));
    final profilesAsync = ref.watch(clubMemberProfilesProvider(clubId));

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Invite section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite Members',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  clubAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                    data: (club) {
                      if (club == null) return const SizedBox.shrink();
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    club.inviteCode ?? '------',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  if (club.inviteCode != null) {
                                    Clipboard.setData(
                                      ClipboardData(text: club.inviteCode!),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Code copied!'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                if (club.inviteCode != null) {
                                  Share.share(
                                    'Join my book club on BookClub! Use invite code: ${club.inviteCode}',
                                  );
                                }
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('Share Invite Link'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Members list
          Text(
            'Members',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (members) {
              final profiles = profilesAsync.valueOrNull ?? {};
              return Column(
                children: members.map((member) {
                  final profile = profiles[member.userId];
                  final displayName = profile?.displayName ?? 'Unknown';
                  final initial = displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile?.avatarUrl != null
                          ? NetworkImage(profile!.avatarUrl!)
                          : null,
                      child: profile?.avatarUrl == null
                          ? Text(initial)
                          : null,
                    ),
                    title: Text(displayName),
                    subtitle: Text(member.isAdmin ? 'Admin' : 'Member'),
                    trailing: member.isAdmin
                        ? const Chip(label: Text('Admin'))
                        : null,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
