import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/providers/club_provider.dart';

class ClubHomeScreen extends ConsumerWidget {
  final String clubId;

  const ClubHomeScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(clubProvider(clubId));

    return clubAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
      data: (club) {
        if (club == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Club not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(club.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => context.pushNamed(
                  RouteNames.chat,
                  pathParameters: {'clubId': clubId},
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.pushNamed(
                  RouteNames.clubSettings,
                  pathParameters: {'clubId': clubId},
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Meeting card placeholder
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Meeting',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No meetings scheduled',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => context.pushNamed(
                          RouteNames.scheduleMeeting,
                          pathParameters: {'clubId': clubId},
                        ),
                        child: const Text('Schedule Meeting'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Current book & progress placeholder
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Currently Reading',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      if (club.currentBookId == null)
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.menu_book,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              const Text('No book selected yet'),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => context.pushNamed(
                                  RouteNames.scanBook,
                                  pathParameters: {'clubId': clubId},
                                ),
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Set Current Book'),
                              ),
                            ],
                          ),
                        )
                      else
                        const Center(
                          child: Text('Progress bars will appear here'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Members section
              Card(
                child: ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('Members'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(
                    RouteNames.inviteMembers,
                    pathParameters: {'clubId': clubId},
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: club.currentBookId != null
              ? FloatingActionButton.extended(
                  onPressed: () => context.pushNamed(
                    RouteNames.updateProgress,
                    pathParameters: {'clubId': clubId},
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Update Progress'),
                )
              : null,
        );
      },
    );
  }
}
