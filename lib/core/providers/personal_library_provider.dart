import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../models/club.dart';
import '../models/personal_book.dart';
import '../services/firebase_service.dart';
import 'club_provider.dart';

/// Streams all personal books for the current user.
final personalBooksProvider =
    StreamProvider.autoDispose<List<PersonalBook>>((ref) {
  final userId = FirebaseService.currentUserId;
  if (userId == null) return const Stream.empty();

  return FirebaseService.personalBooks(userId)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => PersonalBook.fromJson(
                FirebaseService.docToJson(doc, extra: {'user_id': userId}),
              ))
          .toList());
});

/// Notifier for personal library actions.
class PersonalLibraryNotifier extends StateNotifier<AsyncValue<void>> {
  PersonalLibraryNotifier() : super(const AsyncValue.data(null));

  /// Add a book to the personal library.
  Future<void> addBook({
    required Book book,
    required Shelf shelf,
    bool isOwned = false,
  }) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.personalBooks(userId).add({
        'user_id': userId,
        'book_id': book.id,
        'title': book.title,
        'author': book.author,
        'cover_url': book.coverUrl,
        'shelf': _shelfToString(shelf),
        'is_owned': isOwned,
        'percent_complete': 0.0,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Also save the book to the global catalog if needed.
      final existing = await FirebaseService.books.doc(book.id).get();
      if (!existing.exists) {
        await FirebaseService.books.doc(book.id).set({
          ...book.toJson(),
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Move a book to a different shelf.
  Future<void> moveToShelf({
    required String personalBookId,
    required Shelf shelf,
  }) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updates = <String, dynamic>{
        'shelf': _shelfToString(shelf),
      };
      if (shelf == Shelf.finished) {
        updates['finished_at'] = DateTime.now().toIso8601String();
        updates['percent_complete'] = 100.0;
      }
      await FirebaseService.personalBooks(userId)
          .doc(personalBookId)
          .update(updates);
    });
  }

  /// Toggle the owned status of a book.
  Future<void> toggleOwned({
    required String personalBookId,
    required bool isOwned,
  }) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.personalBooks(userId)
          .doc(personalBookId)
          .update({'is_owned': isOwned});
    });
  }

  /// Remove a book from the personal library.
  Future<void> removeBook({required String personalBookId}) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.personalBooks(userId)
          .doc(personalBookId)
          .delete();
    });
  }

  static String _shelfToString(Shelf shelf) {
    switch (shelf) {
      case Shelf.reading:
        return 'reading';
      case Shelf.wantToRead:
        return 'want_to_read';
      case Shelf.finished:
        return 'finished';
    }
  }
}

final personalLibraryNotifierProvider =
    StateNotifierProvider<PersonalLibraryNotifier, AsyncValue<void>>((ref) {
  return PersonalLibraryNotifier();
});

// ── Club current books for the Reading tab ─────────────────────────

/// A club's current book with metadata for cross-referencing.
class ClubCurrentBook {
  final Club club;
  final Book book;
  final String? sourceBookId;

  const ClubCurrentBook({
    required this.club,
    required this.book,
    this.sourceBookId,
  });
}

/// Provides all club current books for the logged-in user.
final clubCurrentBooksProvider =
    FutureProvider.autoDispose<List<ClubCurrentBook>>((ref) async {
  final clubs = await ref.watch(userClubsProvider.future);

  final results = <ClubCurrentBook>[];
  for (final club in clubs) {
    if (club.currentBookId == null) continue;

    final book = await ref.watch(currentBookProvider(club.id).future);
    if (book == null) continue;

    // Read source_book_id from the club's book document.
    final bookDoc = await FirebaseService.clubBooks(club.id)
        .doc(club.currentBookId)
        .get();
    final sourceBookId = bookDoc.data()?['source_book_id'] as String?;

    results.add(ClubCurrentBook(
      club: club,
      book: book,
      sourceBookId: sourceBookId,
    ));
  }

  return results;
});
