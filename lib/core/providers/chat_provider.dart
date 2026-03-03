import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../services/firebase_service.dart';

/// Provides a real-time stream of chat messages for a club, ordered by time.
final clubMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, clubId) {
  return FirebaseService.clubMessages(clubId)
      .orderBy('created_at', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ChatMessage.fromJson(
              FirebaseService.docToJson(doc, extra: {'club_id': clubId}),
            ),
          )
          .toList(),
      );
});

/// Notifier for sending chat messages.
class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  ChatNotifier() : super(const AsyncValue.data(null));

  Future<void> sendMessage({
    required String clubId,
    required String content,
    bool isSpoiler = false,
  }) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.clubMessages(clubId).add({
        'user_id': userId,
        'message_type': 'text',
        'content': trimmed,
        'is_spoiler': isSpoiler,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }
}

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  return ChatNotifier();
});
