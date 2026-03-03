import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../services/firebase_service.dart';

/// Main chat feed: top-level messages only (no replies), excluding dismissed
/// prompts and other users' pending prompts.
final clubMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, clubId) {
  final currentUserId = FirebaseService.currentUserId;

  return FirebaseService.clubMessages(clubId)
      .where('parent_id', isEqualTo: null)
      .orderBy('created_at', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ChatMessage.fromJson(
                FirebaseService.docToJson(doc, extra: {'club_id': clubId}),
              ))
          .where((msg) {
            if (!msg.isPrompt) return true;
            if (msg.promptStatus == PromptStatus.approved) return true;
            if (msg.isPendingPrompt && msg.userId == currentUserId) return true;
            return false;
          })
          .toList());
});

/// Stream of replies to a specific prompt message.
final promptRepliesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, ({String clubId, String promptId})>(
        (ref, params) {
  return FirebaseService.clubMessages(params.clubId)
      .where('parent_id', isEqualTo: params.promptId)
      .orderBy('created_at', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ChatMessage.fromJson(
                FirebaseService.docToJson(doc,
                    extra: {'club_id': params.clubId}),
              ))
          .toList());
});

/// Stream of pending discussion prompts awaiting admin approval.
final pendingPromptsProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, clubId) {
  return FirebaseService.clubMessages(clubId)
      .where('message_type', isEqualTo: 'prompt')
      .where('prompt_status', isEqualTo: 'pending')
      .orderBy('created_at', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ChatMessage.fromJson(
                FirebaseService.docToJson(doc, extra: {'club_id': clubId}),
              ))
          .toList());
});

/// Notifier for sending chat messages, prompts, and replies.
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
        'parent_id': null,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Posts a discussion prompt. Admins get auto-approved; members get 'pending'.
  Future<void> submitPrompt({
    required String clubId,
    required String content,
    required bool isAdmin,
  }) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.clubMessages(clubId).add({
        'user_id': userId,
        'message_type': 'prompt',
        'content': trimmed,
        'is_spoiler': false,
        'parent_id': null,
        'prompt_status': isAdmin ? 'approved' : 'pending',
        'reply_count': 0,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Admin approves a pending prompt.
  Future<void> approvePrompt({
    required String clubId,
    required String messageId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.clubMessages(clubId).doc(messageId).update({
        'prompt_status': 'approved',
      });
    });
  }

  /// Admin dismisses a pending prompt.
  Future<void> dismissPrompt({
    required String clubId,
    required String messageId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.clubMessages(clubId).doc(messageId).update({
        'prompt_status': 'dismissed',
      });
    });
  }

  /// Sends a reply to a discussion prompt.
  Future<void> sendReply({
    required String clubId,
    required String promptId,
    required String content,
  }) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final batch = FirebaseService.firestore.batch();

      final replyRef = FirebaseService.clubMessages(clubId).doc();
      batch.set(replyRef, {
        'user_id': userId,
        'message_type': 'text',
        'content': trimmed,
        'is_spoiler': false,
        'parent_id': promptId,
        'created_at': FieldValue.serverTimestamp(),
      });

      batch.update(FirebaseService.clubMessages(clubId).doc(promptId), {
        'reply_count': FieldValue.increment(1),
      });

      await batch.commit();
    });
  }
}

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  return ChatNotifier();
});
