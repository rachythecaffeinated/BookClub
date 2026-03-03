import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/models/book.dart';
import '../../../core/models/book_pick.dart';
import '../../../core/models/book_proposal.dart';
import '../../../core/providers/book_pick_provider.dart';
import '../../../core/providers/club_provider.dart';

class BookPickScreen extends ConsumerWidget {
  final String clubId;

  const BookPickScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickAsync = ref.watch(activeBookPickProvider(clubId));
    final completedAsync = ref.watch(completedBookPickProvider(clubId));
    final memberAsync = ref.watch(currentUserMemberProvider(clubId));

    return Scaffold(
      appBar: AppBar(title: const Text('Book Pick')),
      body: pickAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (activePick) {
          if (activePick != null) {
            return _ActivePickBody(
              clubId: clubId,
              pick: activePick,
              isAdmin: memberAsync.valueOrNull?.role.name == 'admin',
            );
          }

          // No active pick — check for completed one
          return completedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (completed) {
              if (completed != null) {
                return _CompletedPickBody(
                  clubId: clubId,
                  pick: completed,
                  isAdmin: memberAsync.valueOrNull?.role.name == 'admin',
                );
              }
              return _NoActivePickView(
                clubId: clubId,
                isAdmin: memberAsync.valueOrNull?.role.name == 'admin',
              );
            },
          );
        },
      ),
    );
  }
}

// ── Active pick body — delegates to proposing/rating views ─────────

class _ActivePickBody extends ConsumerWidget {
  final String clubId;
  final BookPick pick;
  final bool isAdmin;

  const _ActivePickBody({
    required this.clubId,
    required this.pick,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (clubId: clubId, bookPickId: pick.id);

    if (pick.isProposing) {
      final hasParticipated = ref.watch(hasParticipatedProvider(params));
      return hasParticipated.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (participated) {
          if (participated) {
            return _WaitingView(
              pick: pick,
              message: 'Waiting for others to propose or vote...',
              isAdmin: isAdmin,
            );
          }
          return _ProposingView(
            clubId: clubId,
            pick: pick,
            isAdmin: isAdmin,
          );
        },
      );
    }

    if (pick.isRating) {
      final hasRated = ref.watch(hasRatedProvider(params));
      return hasRated.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rated) {
          if (rated) {
            return _WaitingView(
              pick: pick,
              message: 'Waiting for others to rate...',
              isAdmin: isAdmin,
            );
          }
          return _RatingView(clubId: clubId, pick: pick);
        },
      );
    }

    return const SizedBox.shrink();
  }
}

// ── Completed pick body — results or tie breaker ───────────────────

class _CompletedPickBody extends ConsumerWidget {
  final String clubId;
  final BookPick pick;
  final bool isAdmin;

  const _CompletedPickBody({
    required this.clubId,
    required this.pick,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pick.hasTie) {
      final proposalsAsync = ref.watch(
        bookPickProposalsProvider((clubId: clubId, bookPickId: pick.id)),
      );
      return proposalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (proposals) {
          final tiedProposals = proposals
              .where((p) => pick.tiedProposalIds!.contains(p.id))
              .toList();
          return _TieBreakerView(
            clubId: clubId,
            pick: pick,
            tiedProposals: tiedProposals,
            isAdmin: isAdmin,
          );
        },
      );
    }

    return _ResultsView(clubId: clubId, pick: pick, isAdmin: isAdmin);
  }
}

// ── No active pick ─────────────────────────────────────────────────

class _NoActivePickView extends ConsumerWidget {
  final String clubId;
  final bool isAdmin;

  const _NoActivePickView({required this.clubId, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No book pick in progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a Book Pick to let members propose and vote on what to read next.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await ref
                      .read(bookPickNotifierProvider.notifier)
                      .createBookPick(clubId: clubId);
                  ref.invalidate(activeBookPickProvider(clubId));
                },
                icon: const Icon(Icons.rocket_launch),
                label: const Text('Start Book Pick'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Proposing view (Round 1) ───────────────────────────────────────

class _ProposingView extends ConsumerWidget {
  final String clubId;
  final BookPick pick;
  final bool isAdmin;

  const _ProposingView({
    required this.clubId,
    required this.pick,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(
      bookPickProposalsProvider((clubId: clubId, bookPickId: pick.id)),
    );

    return Column(
      children: [
        // Participation tracker
        _ParticipationTracker(pick: pick, isAdmin: isAdmin),

        // Propose button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.pushNamed(
                RouteNames.bookPickPropose,
                pathParameters: {'clubId': clubId},
                extra: pick,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Propose a Book'),
            ),
          ),
        ),

        if (proposalsAsync.valueOrNull?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Or vote for one already proposed:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Proposals list
        Expanded(
          child: proposalsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (proposals) {
              if (proposals.isEmpty) {
                return Center(
                  child: Text(
                    'No books proposed yet. Be the first!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: proposals.length,
                itemBuilder: (context, index) {
                  final proposal = proposals[index];
                  return _ProposalCard(
                    proposal: proposal,
                    showVoteButton: true,
                    onVote: () async {
                      await ref
                          .read(bookPickNotifierProvider.notifier)
                          .voteForProposal(
                            clubId: clubId,
                            bookPickId: pick.id,
                            proposalId: proposal.id,
                            memberCount: pick.memberCount,
                          );
                      ref.invalidate(activeBookPickProvider(clubId));
                      ref.invalidate(bookPickProposalsProvider(
                          (clubId: clubId, bookPickId: pick.id)));
                      ref.invalidate(hasParticipatedProvider(
                          (clubId: clubId, bookPickId: pick.id)));
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Waiting view ───────────────────────────────────────────────────

class _WaitingView extends StatelessWidget {
  final BookPick pick;
  final String message;
  final bool isAdmin;

  const _WaitingView({
    required this.pick,
    required this.message,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ParticipationTracker(pick: pick, isAdmin: isAdmin),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              pick.isProposing
                  ? '${pick.participantCount} of ${pick.memberCount} members'
                  : '${pick.ratingCount} of ${pick.memberCount} members',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rating view (Round 2) ──────────────────────────────────────────

class _RatingView extends ConsumerStatefulWidget {
  final String clubId;
  final BookPick pick;

  const _RatingView({required this.clubId, required this.pick});

  @override
  ConsumerState<_RatingView> createState() => _RatingViewState();
}

class _RatingViewState extends ConsumerState<_RatingView> {
  final Map<String, int> _ratings = {};

  @override
  Widget build(BuildContext context) {
    final proposalsAsync = ref.watch(
      bookPickProposalsProvider(
          (clubId: widget.clubId, bookPickId: widget.pick.id)),
    );

    return proposalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (proposals) {
        final allRated = proposals.every((p) => _ratings.containsKey(p.id));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Rate each book',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: proposals.length,
                itemBuilder: (context, index) {
                  final proposal = proposals[index];
                  return _RatingCard(
                    proposal: proposal,
                    selectedScore: _ratings[proposal.id],
                    onRatingChanged: (score) {
                      setState(() => _ratings[proposal.id] = score);
                    },
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: allRated
                        ? () async {
                            await ref
                                .read(bookPickNotifierProvider.notifier)
                                .submitRatings(
                                  clubId: widget.clubId,
                                  bookPickId: widget.pick.id,
                                  ratings: _ratings,
                                  memberCount: widget.pick.memberCount,
                                );
                            ref.invalidate(
                                activeBookPickProvider(widget.clubId));
                            ref.invalidate(
                                completedBookPickProvider(widget.clubId));
                            ref.invalidate(hasRatedProvider((
                              clubId: widget.clubId,
                              bookPickId: widget.pick.id,
                            )));
                          }
                        : null,
                    child: Text(allRated
                        ? 'Submit Ratings'
                        : 'Rate all ${proposals.length} books to continue'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Results view ───────────────────────────────────────────────────

class _ResultsView extends ConsumerWidget {
  final String clubId;
  final BookPick pick;
  final bool isAdmin;

  const _ResultsView({
    required this.clubId,
    required this.pick,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(
      bookPickProposalsProvider((clubId: clubId, bookPickId: pick.id)),
    );

    return proposalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (proposals) {
        final winner =
            proposals.where((p) => p.id == pick.winnerProposalId).firstOrNull;
        final ranked = proposals.where((p) => !p.eliminated).toList()
          ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
        final eliminated = proposals.where((p) => p.eliminated).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Winner banner
            if (winner != null) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        pick.tiebroken ? Icons.casino : Icons.emoji_events,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pick.tiebroken ? 'Winner (by random draw)' : 'Winner',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        winner.title,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'by ${winner.author}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Score: ${winner.totalScore}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await ref
                                .read(clubNotifierProvider.notifier)
                                .setCurrentBook(
                                  clubId: clubId,
                                  book: _proposalToBook(winner),
                                );
                            ref.invalidate(clubProvider(clubId));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${winner.title} set as current book!')),
                              );
                            }
                          },
                          icon: const Icon(Icons.menu_book),
                          label: const Text('Set as Current Book'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // No winner (all eliminated)
            if (pick.winnerProposalId == null && !pick.hasTie) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.sentiment_dissatisfied,
                          size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      const Text('All books were eliminated!'),
                      const SizedBox(height: 4),
                      Text(
                        'Try starting a new Book Pick with different proposals.',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await ref
                                .read(bookPickNotifierProvider.notifier)
                                .createBookPick(clubId: clubId);
                            ref.invalidate(activeBookPickProvider(clubId));
                            ref.invalidate(completedBookPickProvider(clubId));
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Start New Book Pick'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // All ranked results
            if (ranked.isNotEmpty) ...[
              Text('Rankings',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[600],
                      )),
              const SizedBox(height: 8),
              ...ranked.map((p) => _ProposalCard(
                    proposal: p,
                    showScore: true,
                    isWinner: p.id == pick.winnerProposalId,
                  )),
            ],

            // Eliminated
            if (eliminated.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Eliminated',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[600],
                      )),
              const SizedBox(height: 8),
              ...eliminated.map((p) => _ProposalCard(
                    proposal: p,
                    showScore: true,
                    isEliminated: true,
                  )),
            ],
          ],
        );
      },
    );
  }
}

// ── Tie breaker view (randomizer) ──────────────────────────────────

class _TieBreakerView extends ConsumerStatefulWidget {
  final String clubId;
  final BookPick pick;
  final List<BookProposal> tiedProposals;
  final bool isAdmin;

  const _TieBreakerView({
    required this.clubId,
    required this.pick,
    required this.tiedProposals,
    required this.isAdmin,
  });

  @override
  ConsumerState<_TieBreakerView> createState() => _TieBreakerViewState();
}

class _TieBreakerViewState extends ConsumerState<_TieBreakerView>
    with SingleTickerProviderStateMixin {
  late final FixedExtentScrollController _scrollController;
  late final AnimationController _animController;
  bool _spinning = false;
  bool _resolved = false;
  int _winnerIndex = 0;

  // Build repeated list for the slot-machine effect
  late final List<BookProposal> _repeatedItems;
  static const int _repeatCount = 12;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Build the repeated list
    _repeatedItems = [];
    for (int i = 0; i < _repeatCount; i++) {
      _repeatedItems.addAll(widget.tiedProposals);
    }

    // Pre-calculate the winner: pick a random index in the last cycle
    final random = Random();
    final lastCycleStart =
        (_repeatCount - 1) * widget.tiedProposals.length;
    _winnerIndex = lastCycleStart +
        random.nextInt(widget.tiedProposals.length);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    setState(() => _spinning = true);

    // Animate to the winner
    await _scrollController.animateToItem(
      _winnerIndex,
      duration: const Duration(milliseconds: 3000),
      curve: Curves.easeOutCubic,
    );

    final winner = _repeatedItems[_winnerIndex];

    // Save the result
    await ref.read(bookPickNotifierProvider.notifier).resolveTie(
          clubId: widget.clubId,
          bookPickId: widget.pick.id,
          winnerProposalId: winner.id,
          winnerTitle: winner.title,
        );

    ref.invalidate(activeBookPickProvider(widget.clubId));
    ref.invalidate(completedBookPickProvider(widget.clubId));

    if (mounted) {
      setState(() {
        _spinning = false;
        _resolved = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.casino, size: 48, color: primary),
            const SizedBox(height: 16),
            Text(
              "It's a tie!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.tiedProposals.length} books tied with the same score',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Slot machine
            SizedBox(
              height: 200,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.25, 0.75, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: ListWheelScrollView.useDelegate(
                  controller: _scrollController,
                  itemExtent: 70,
                  perspective: 0.003,
                  physics: const NeverScrollableScrollPhysics(),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _repeatedItems.length,
                    builder: (context, index) {
                      final proposal = _repeatedItems[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _resolved && index == _winnerIndex
                              ? primary.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _resolved && index == _winnerIndex
                                ? primary
                                : Colors.grey[300]!,
                            width: _resolved && index == _winnerIndex ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (proposal.coverUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  proposal.coverUrl!,
                                  width: 32,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _miniBookPlaceholder(),
                                ),
                              )
                            else
                              _miniBookPlaceholder(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    proposal.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                  ),
                                  Text(
                                    proposal.author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Center indicator
            Icon(Icons.arrow_drop_up, size: 32, color: primary),

            const SizedBox(height: 16),

            if (!_resolved && widget.isAdmin)
              ElevatedButton.icon(
                onPressed: _spinning ? null : _spin,
                icon: _spinning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.casino),
                label: Text(_spinning ? 'Spinning...' : 'Spin!'),
              ),

            if (!_resolved && !widget.isAdmin)
              Text(
                'Waiting for admin to spin the wheel...',
                style: TextStyle(color: Colors.grey[600]),
              ),

            if (_resolved) ...[
              const SizedBox(height: 8),
              Text(
                'Winner selected!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniBookPlaceholder() {
    return Container(
      width: 32,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.menu_book, size: 16, color: Colors.grey[400]),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────

class _ParticipationTracker extends StatelessWidget {
  final BookPick pick;
  final bool isAdmin;

  const _ParticipationTracker({required this.pick, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final current =
        pick.isProposing ? pick.participantCount : pick.ratingCount;
    final total = pick.memberCount;
    final label = pick.isProposing
        ? 'Round 1: Propose & Vote'
        : 'Round 2: Rate Books';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '$current / $total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? current / total : 0,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final BookProposal proposal;
  final bool showVoteButton;
  final bool showScore;
  final bool isWinner;
  final bool isEliminated;
  final VoidCallback? onVote;

  const _ProposalCard({
    required this.proposal,
    this.showVoteButton = false,
    this.showScore = false,
    this.isWinner = false,
    this.isEliminated = false,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isEliminated ? Colors.grey[100] : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            SizedBox(
              width: 40,
              height: 60,
              child: proposal.coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        proposal.coverUrl!,
                        width: 40,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      ),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proposal.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration:
                              isEliminated ? TextDecoration.lineThrough : null,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    proposal.author,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (showScore) ...[
                        _chip(
                          context,
                          'Score: ${proposal.totalScore}',
                          isEliminated ? Colors.grey : Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        if (proposal.vetoCount > 0)
                          _chip(
                            context,
                            '${proposal.vetoCount} veto${proposal.vetoCount != 1 ? 's' : ''}',
                            Colors.red,
                          ),
                      ] else ...[
                        _chip(
                          context,
                          '${proposal.voteCount} vote${proposal.voteCount != 1 ? 's' : ''}',
                          Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (showVoteButton && onVote != null)
              TextButton(
                onPressed: onVote,
                child: const Text('Vote'),
              ),
            if (isWinner)
              Icon(Icons.emoji_events,
                  color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 11,
            ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 40,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.menu_book, size: 16, color: Colors.grey[400]),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final BookProposal proposal;
  final int? selectedScore;
  final ValueChanged<int> onRatingChanged;

  const _RatingCard({
    required this.proposal,
    this.selectedScore,
    required this.onRatingChanged,
  });

  static const _options = [
    (label: 'Really want', score: 3, color: Colors.green),
    (label: 'Would read', score: 1, color: Colors.lightGreen),
    (label: 'Neutral', score: 0, color: Colors.grey),
    (label: 'Pass', score: -2, color: Colors.red),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 48,
                  child: proposal.coverUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            proposal.coverUrl!,
                            width: 32,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          ),
                        )
                      : _placeholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proposal.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        proposal.author,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _options.map((option) {
                final isSelected = selectedScore == option.score;
                return ChoiceChip(
                  label: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : option.color,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: option.color,
                  backgroundColor: option.color.withValues(alpha: 0.1),
                  onSelected: (_) => onRatingChanged(option.score),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 32,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.menu_book, size: 14, color: Colors.grey[400]),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────

Book _proposalToBook(BookProposal proposal) {
  return Book(
    id: '',
    isbn: proposal.isbn,
    title: proposal.title,
    author: proposal.author,
    coverUrl: proposal.coverUrl,
    pageCount: proposal.pageCount,
    description: proposal.description,
    createdAt: DateTime.now(),
  );
}
