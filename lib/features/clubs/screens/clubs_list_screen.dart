import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/models/club.dart';
import '../../../core/providers/club_provider.dart';
import '../../../shared/widgets/screen_header.dart';

class ClubsListScreen extends ConsumerWidget {
  const ClubsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(userClubsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: clubsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(userClubsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (clubs) {
            if (clubs.isEmpty) {
              return _EmptyState();
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(userClubsProvider),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const ScreenHeader(
                    sectionLabel: 'COMMUNITY HUB',
                    titlePrefix: 'My ',
                    titleAccent: 'Clubs',
                  ),
                  // Featured club (first club)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _FeaturedClubCard(club: clubs.first),
                  ),
                  if (clubs.length > 1) ...[
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'EXPLORE CLUBS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...clubs.skip(1).map((club) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _ClubListTile(club: club),
                        )),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: clubsAsync.maybeWhen(
        data: (clubs) => clubs.isNotEmpty
            ? FloatingActionButton(
                onPressed: () => _showAddOptions(context),
                child: const Icon(Icons.add),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create a Club'),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed(RouteNames.createClub);
              },
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key_outlined),
              title: const Text('Join with Code'),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed(RouteNames.joinClub);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ScreenHeader(
          sectionLabel: 'COMMUNITY HUB',
          titlePrefix: 'My ',
          titleAccent: 'Clubs',
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.menu_book, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No clubs yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Create or join a book club to get started',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pushNamed(RouteNames.createClub),
                child: const Text('Create a Club'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.pushNamed(RouteNames.joinClub),
                child: const Text('Join with Code'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedClubCard extends StatelessWidget {
  final Club club;

  const _FeaturedClubCard({required this.club});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        RouteNames.clubHome,
        pathParameters: {'clubId': club.id},
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.primaryDark],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              club.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (club.description != null && club.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Currently reading: ${club.description!}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            // Member avatars row
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 32,
                  child: Stack(
                    children: List.generate(
                      3.clamp(0, club.memberCount),
                      (i) => Positioned(
                        left: i * 20.0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.3),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (club.memberCount > 3)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${club.memberCount - 3}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Join Discussion button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'JOIN DISCUSSION',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubListTile extends StatelessWidget {
  final Club club;

  const _ClubListTile({required this.club});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.clubHome,
          pathParameters: {'clubId': club.id},
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: club.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          club.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              club.name.isNotEmpty
                                  ? club.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          club.name.isNotEmpty
                              ? club.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${club.memberCount} ${club.memberCount == 1 ? 'member' : 'members'}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Join',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
