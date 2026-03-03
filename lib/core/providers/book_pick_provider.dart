import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../models/book_pick.dart';
import '../models/book_proposal.dart';
import '../services/firebase_service.dart';

// ── Read providers ─────────────────────────────────────────────────────

/// Active book pick for a club (status != completed), or null.
final activeBookPickProvider = FutureProvider.autoDispose
    .family<BookPick?, String>((ref, clubId) async {
  final snapshot = await FirebaseService.bookPicks(clubId)
      .where('status', whereIn: ['proposing', 'rating'])
      .limit(1)
      .get();
  if (snapshot.docs.isEmpty) return null;
  return BookPick.fromJson(
    FirebaseService.docToJson(snapshot.docs.first, extra: {'club_id': clubId}),
  );
});

/// Most recently completed book pick for a club, or null.
final completedBookPickProvider = FutureProvider.autoDispose
    .family<BookPick?, String>((ref, clubId) async {
  final snapshot = await FirebaseService.bookPicks(clubId)
      .where('status', isEqualTo: 'completed')
      .orderBy('completed_at', descending: true)
      .limit(1)
      .get();
  if (snapshot.docs.isEmpty) return null;
  return BookPick.fromJson(
    FirebaseService.docToJson(snapshot.docs.first, extra: {'club_id': clubId}),
  );
});

/// All proposals for a given book pick.
final bookPickProposalsProvider = FutureProvider.autoDispose
    .family<List<BookProposal>, ({String clubId, String bookPickId})>(
        (ref, params) async {
  final snapshot = await FirebaseService.bookPickProposals(
          params.clubId, params.bookPickId)
      .orderBy('vote_count', descending: true)
      .get();
  return snapshot.docs
      .map((doc) => BookProposal.fromJson(
            FirebaseService.docToJson(doc,
                extra: {'book_pick_id': params.bookPickId}),
          ))
      .toList();
});

/// Whether the current user has participated in round 1.
final hasParticipatedProvider = FutureProvider.autoDispose
    .family<bool, ({String clubId, String bookPickId})>(
        (ref, params) async {
  final userId = FirebaseService.currentUserId;
  if (userId == null) return false;
  final doc = await FirebaseService.bookPickParticipants(
          params.clubId, params.bookPickId)
      .doc(userId)
      .get();
  return doc.exists;
});

/// Whether the current user has submitted ratings in round 2.
final hasRatedProvider = FutureProvider.autoDispose
    .family<bool, ({String clubId, String bookPickId})>(
        (ref, params) async {
  final userId = FirebaseService.currentUserId;
  if (userId == null) return false;
  final doc = await FirebaseService.bookPickRatings(
          params.clubId, params.bookPickId)
      .doc(userId)
      .get();
  return doc.exists;
});

// ── Mutation notifier ──────────────────────────────────────────────────

class BookPickNotifier extends StateNotifier<AsyncValue<void>> {
  BookPickNotifier() : super(const AsyncValue.data(null));

  /// Admin creates a new Book Pick event.
  Future<void> createBookPick({required String clubId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      final membersSnapshot = await FirebaseService.clubMembers(clubId)
          .where('status', isEqualTo: 'accepted')
          .get();

      await FirebaseService.bookPicks(clubId).doc().set({
        'club_id': clubId,
        'created_by': userId,
        'status': 'proposing',
        'member_count': membersSnapshot.docs.length,
        'participant_count': 0,
        'rating_count': 0,
        'tiebroken': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Member proposes a new book (counts as their round 1 participation).
  Future<void> proposeBook({
    required String clubId,
    required String bookPickId,
    required Book book,
    required int memberCount,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      final batch = FirebaseService.firestore.batch();

      final proposalRef =
          FirebaseService.bookPickProposals(clubId, bookPickId).doc();
      batch.set(proposalRef, {
        'book_pick_id': bookPickId,
        'proposed_by': userId,
        'title': book.title,
        'author': book.author,
        'cover_url': book.coverUrl,
        'page_count': book.pageCount,
        'isbn': book.isbn,
        'description': book.description,
        'voted_by': [userId],
        'vote_count': 1,
        'total_score': 0,
        'eliminated': false,
        'veto_count': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      batch.set(
        FirebaseService.bookPickParticipants(clubId, bookPickId).doc(userId),
        {
          'participated': true,
          'action': 'propose',
          'proposal_id': proposalRef.id,
        },
      );

      batch.update(FirebaseService.bookPicks(clubId).doc(bookPickId), {
        'participant_count': FieldValue.increment(1),
      });

      await batch.commit();

      await _checkRoundAdvance(
        clubId: clubId,
        bookPickId: bookPickId,
        memberCount: memberCount,
      );
    });
  }

  /// Member votes for an existing proposal (round 1).
  Future<void> voteForProposal({
    required String clubId,
    required String bookPickId,
    required String proposalId,
    required int memberCount,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      final batch = FirebaseService.firestore.batch();

      batch.update(
        FirebaseService.bookPickProposals(clubId, bookPickId).doc(proposalId),
        {
          'voted_by': FieldValue.arrayUnion([userId]),
          'vote_count': FieldValue.increment(1),
        },
      );

      batch.set(
        FirebaseService.bookPickParticipants(clubId, bookPickId).doc(userId),
        {
          'participated': true,
          'action': 'vote',
          'proposal_id': proposalId,
        },
      );

      batch.update(FirebaseService.bookPicks(clubId).doc(bookPickId), {
        'participant_count': FieldValue.increment(1),
      });

      await batch.commit();

      await _checkRoundAdvance(
        clubId: clubId,
        bookPickId: bookPickId,
        memberCount: memberCount,
      );
    });
  }

  /// Member submits ratings for all proposals (round 2).
  Future<void> submitRatings({
    required String clubId,
    required String bookPickId,
    required Map<String, int> ratings,
    required int memberCount,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      final batch = FirebaseService.firestore.batch();

      batch.set(
        FirebaseService.bookPickRatings(clubId, bookPickId).doc(userId),
        {
          'book_pick_id': bookPickId,
          'user_id': userId,
          'ratings': ratings,
          'created_at': FieldValue.serverTimestamp(),
        },
      );

      batch.update(FirebaseService.bookPicks(clubId).doc(bookPickId), {
        'rating_count': FieldValue.increment(1),
      });

      await batch.commit();

      await _checkRatingComplete(
        clubId: clubId,
        bookPickId: bookPickId,
        memberCount: memberCount,
      );
    });
  }

  /// Called after the randomizer animation resolves a tie.
  Future<void> resolveTie({
    required String clubId,
    required String bookPickId,
    required String winnerProposalId,
    required String winnerTitle,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.bookPicks(clubId).doc(bookPickId).update({
        'winner_proposal_id': winnerProposalId,
        'winner_title': winnerTitle,
        'tiebroken': true,
        'tied_proposal_ids': FieldValue.delete(),
        'completed_at': FieldValue.serverTimestamp(),
      });
    });
  }

  // ── Internal helpers ───────────────────────────────────────────────

  Future<void> _checkRoundAdvance({
    required String clubId,
    required String bookPickId,
    required int memberCount,
  }) async {
    final doc = await FirebaseService.bookPicks(clubId).doc(bookPickId).get();
    final data = doc.data()!;
    final participantCount = data['participant_count'] as int;

    if (participantCount >= memberCount) {
      await FirebaseService.bookPicks(clubId).doc(bookPickId).update({
        'status': 'rating',
      });
    }
  }

  Future<void> _checkRatingComplete({
    required String clubId,
    required String bookPickId,
    required int memberCount,
  }) async {
    final doc = await FirebaseService.bookPicks(clubId).doc(bookPickId).get();
    final data = doc.data()!;
    final ratingCount = data['rating_count'] as int;

    if (ratingCount >= memberCount) {
      await _computeResults(
        clubId: clubId,
        bookPickId: bookPickId,
        memberCount: memberCount,
      );
    }
  }

  Future<void> _computeResults({
    required String clubId,
    required String bookPickId,
    required int memberCount,
  }) async {
    final ratingsSnapshot =
        await FirebaseService.bookPickRatings(clubId, bookPickId).get();
    final allRatings = ratingsSnapshot.docs.map((doc) {
      return Map<String, int>.from(doc.data()['ratings'] as Map);
    }).toList();

    final proposalsSnapshot =
        await FirebaseService.bookPickProposals(clubId, bookPickId).get();

    final vetoThreshold = (memberCount / 3).ceil();
    final batch = FirebaseService.firestore.batch();

    final scoredProposals = <String, int>{};
    final eliminatedIds = <String>{};

    for (final proposalDoc in proposalsSnapshot.docs) {
      final proposalId = proposalDoc.id;
      int totalScore = 0;
      int vetoCount = 0;

      for (final memberRatings in allRatings) {
        final score = memberRatings[proposalId] ?? 0;
        totalScore += score;
        if (score == -2) vetoCount++;
      }

      final eliminated = vetoCount >= vetoThreshold;

      batch.update(proposalDoc.reference, {
        'total_score': totalScore,
        'veto_count': vetoCount,
        'eliminated': eliminated,
      });

      if (eliminated) {
        eliminatedIds.add(proposalId);
      } else {
        scoredProposals[proposalId] = totalScore;
      }
    }

    if (scoredProposals.isNotEmpty) {
      final maxScore = scoredProposals.values.reduce((a, b) => a > b ? a : b);
      final tiedIds = scoredProposals.entries
          .where((e) => e.value == maxScore)
          .map((e) => e.key)
          .toList();

      if (tiedIds.length == 1) {
        final winnerDoc =
            proposalsSnapshot.docs.firstWhere((d) => d.id == tiedIds.first);
        batch.update(FirebaseService.bookPicks(clubId).doc(bookPickId), {
          'status': 'completed',
          'winner_proposal_id': tiedIds.first,
          'winner_title': winnerDoc.data()['title'],
          'tiebroken': false,
          'completed_at': FieldValue.serverTimestamp(),
        });
      } else {
        batch.update(FirebaseService.bookPicks(clubId).doc(bookPickId), {
          'status': 'completed',
          'tied_proposal_ids': tiedIds,
          'tiebroken': false,
        });
      }
    } else {
      batch.update(FirebaseService.bookPicks(clubId).doc(bookPickId), {
        'status': 'completed',
        'winner_proposal_id': null,
        'winner_title': null,
        'completed_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}

final bookPickNotifierProvider =
    StateNotifierProvider<BookPickNotifier, AsyncValue<void>>((ref) {
  return BookPickNotifier();
});
