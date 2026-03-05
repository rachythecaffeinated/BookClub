import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/margin_note.dart';
import '../services/firebase_service.dart';

/// Stream of margin notes for a specific book in a club.
final bookNotesProvider = StreamProvider.autoDispose
    .family<List<MarginNote>, ({String clubId, String bookId})>(
        (ref, params) {
  final currentUserId = FirebaseService.currentUserId;

  return FirebaseService.clubNotes(params.clubId)
      .where('book_id', isEqualTo: params.bookId)
      .orderBy('created_at', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => MarginNote.fromJson(
                FirebaseService.docToJson(doc,
                    extra: {'club_id': params.clubId}),
              ))
          .where((note) {
            // Show club-visible notes and user's own private notes.
            if (note.visibility == NoteVisibility.club) return true;
            return note.userId == currentUserId;
          })
          .toList());
});

/// Notifier for creating margin notes.
class MarginNoteNotifier extends StateNotifier<AsyncValue<void>> {
  MarginNoteNotifier() : super(const AsyncValue.data(null));

  Future<void> createNote({
    required String clubId,
    required String bookId,
    required String noteText,
    String? quoteText,
    int? pageNumber,
    String visibility = 'club',
  }) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.clubNotes(clubId).add({
        'user_id': userId,
        'club_id': clubId,
        'book_id': bookId,
        'note_text': noteText.trim(),
        'quote_text': quoteText?.trim(),
        'page_number': pageNumber,
        'location_number': null,
        'timestamp_sec': null,
        'percent_position': 0.0,
        'visibility': visibility,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }
}

final marginNoteNotifierProvider =
    StateNotifierProvider<MarginNoteNotifier, AsyncValue<void>>((ref) {
  return MarginNoteNotifier();
});
