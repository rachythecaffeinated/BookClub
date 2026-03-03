import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/models/book.dart';
import '../../../core/models/book_pick.dart';
import '../../../core/models/reading_progress.dart';
import '../../../core/providers/book_pick_provider.dart';
import '../../../core/providers/club_provider.dart';
import '../../../core/providers/progress_provider.dart';

void _showAddBookOptions(BuildContext context, String clubId) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search by title'),
            subtitle: const Text('Find a book by title or author'),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(
                RouteNames.searchBook,
                pathParameters: {'clubId': clubId},
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Scan barcode'),
            subtitle: const Text('Scan the ISBN on the back cover'),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(
                RouteNames.scanBook,
                pathParameters: {'clubId': clubId},
              );
            },
          ),
        ],
      ),
    ),
  );
}

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

              // Book Pick
              _BookPickCard(clubId: clubId),
              const SizedBox(height: 16),

              // Current book & progress
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
                                onPressed: () =>
                                    _showAddBookOptions(context, clubId),
                                icon: const Icon(Icons.add),
                                label: const Text('Set Current Book'),
                              ),
                            ],
                          ),
                        )
                      else
                        _CurrentBookSection(clubId: clubId),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Members section
              Card(
                child: ListTile(
                  leading: const Icon(Icons.group),
                  title: Text(
                    '${club.memberCount} ${club.memberCount == 1 ? 'Member' : 'Members'}',
                  ),
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

class _CurrentBookSection extends ConsumerWidget {
  final String clubId;

  const _CurrentBookSection({required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(currentBookProvider(clubId));
    final progressAsync = ref.watch(clubProgressProvider(clubId));
    final profilesAsync = ref.watch(clubMemberProfilesProvider(clubId));

    return bookAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading book: $e'),
      data: (book) {
        if (book == null) {
          return const Text('Book not found');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book info row
            _BookInfoRow(book: book),
            const SizedBox(height: 16),

            // Progress bars
            progressAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading progress: $e'),
              data: (progressList) {
                final profiles = profilesAsync.valueOrNull ?? {};

                if (progressList.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No one has logged progress yet',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                return Column(
                  children: progressList.map((progress) {
                    final profile = profiles[progress.userId];
                    final name = profile?.displayName ?? 'Unknown';
                    return _MemberProgressBar(
                      name: name,
                      progress: progress,
                      totalPages: book.pageCount,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _BookInfoRow extends StatelessWidget {
  final Book book;

  const _BookInfoRow({required this.book});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover
        SizedBox(
          width: 48,
          height: 72,
          child: book.coverUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    book.coverUrl!,
                    width: 48,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _bookPlaceholder(),
                  ),
                )
              : _bookPlaceholder(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                book.author,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              if (book.pageCount != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${book.pageCount} pages',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _bookPlaceholder() {
    return Container(
      width: 48,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.menu_book, size: 20, color: Colors.grey[400]),
    );
  }
}

class _MemberProgressBar extends StatelessWidget {
  final String name;
  final ReadingProgress progress;
  final int? totalPages;

  const _MemberProgressBar({
    required this.name,
    required this.progress,
    this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final percent = progress.percentComplete / 100.0;
    final primary = Theme.of(context).colorScheme.primary;

    // Build the detail text.
    String detail = '${progress.percentComplete.toStringAsFixed(0)}%';
    if (progress.currentPage != null && totalPages != null) {
      detail = 'pg ${progress.currentPage} of $totalPages';
    } else if (progress.currentPage != null) {
      detail = 'pg ${progress.currentPage}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                progress.isFinished ? Colors.green : primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookPickCard extends ConsumerWidget {
  final String clubId;

  const _BookPickCard({required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickAsync = ref.watch(activeBookPickProvider(clubId));
    final completedAsync = ref.watch(completedBookPickProvider(clubId));
    final memberAsync = ref.watch(currentUserMemberProvider(clubId));

    final isAdmin = memberAsync.valueOrNull?.role.name == 'admin';

    return pickAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (activePick) {
        if (activePick != null) {
          return _buildCard(
            context,
            icon: activePick.isProposing
                ? Icons.how_to_vote
                : Icons.star_rate,
            title: activePick.isProposing
                ? 'Book Pick: Propose & Vote'
                : 'Book Pick: Rate Books',
            subtitle:
                '${activePick.isProposing ? activePick.participantCount : activePick.ratingCount} of ${activePick.memberCount} members',
            buttonLabel: 'Participate',
            onTap: () => context.pushNamed(
              RouteNames.bookPick,
              pathParameters: {'clubId': clubId},
            ),
          );
        }

        // Check for completed pick
        return completedAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (completed) {
            if (completed != null && completed.hasTie) {
              return _buildCard(
                context,
                icon: Icons.casino,
                title: 'Book Pick: Tiebreaker needed!',
                subtitle:
                    '${completed.tiedProposalIds?.length ?? 0} books tied',
                buttonLabel: 'Break the Tie',
                onTap: () => context.pushNamed(
                  RouteNames.bookPick,
                  pathParameters: {'clubId': clubId},
                ),
              );
            }

            if (completed != null && completed.winnerProposalId != null) {
              return _buildCard(
                context,
                icon: Icons.emoji_events,
                title: 'Next book chosen!',
                subtitle: completed.winnerTitle ?? 'View results',
                buttonLabel: 'View Results',
                onTap: () => context.pushNamed(
                  RouteNames.bookPick,
                  pathParameters: {'clubId': clubId},
                ),
              );
            }

            // No active or completed pick — show start button for admin only
            if (!isAdmin) return const SizedBox.shrink();

            return _buildCard(
              context,
              icon: Icons.auto_stories,
              title: 'Pick your next book',
              subtitle:
                  'Let members propose and vote on what to read next',
              buttonLabel: 'Start Book Pick',
              onTap: () => context.pushNamed(
                RouteNames.bookPick,
                pathParameters: {'clubId': clubId},
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
