import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  static String? get currentUserId => auth.currentUser?.id;

  static bool get isAuthenticated => auth.currentUser != null;

  // Table references
  static SupabaseQueryBuilder get users => client.from('users');
  static SupabaseQueryBuilder get clubs => client.from('clubs');
  static SupabaseQueryBuilder get clubMembers => client.from('club_members');
  static SupabaseQueryBuilder get books => client.from('books');
  static SupabaseQueryBuilder get clubBooks => client.from('club_books');
  static SupabaseQueryBuilder get readingProgress =>
      client.from('reading_progress');
  static SupabaseQueryBuilder get progressLog =>
      client.from('progress_log');
  static SupabaseQueryBuilder get marginNotes =>
      client.from('margin_notes');
  static SupabaseQueryBuilder get noteReactions =>
      client.from('note_reactions');
  static SupabaseQueryBuilder get noteReplies =>
      client.from('note_replies');
  static SupabaseQueryBuilder get chatMessages =>
      client.from('chat_messages');
  static SupabaseQueryBuilder get chatReadReceipts =>
      client.from('chat_read_receipts');
  static SupabaseQueryBuilder get personalBooks =>
      client.from('personal_books');
  static SupabaseQueryBuilder get dailyReadingLog =>
      client.from('daily_reading_log');
  static SupabaseQueryBuilder get readingStreaks =>
      client.from('reading_streaks');
  static SupabaseQueryBuilder get readingGoals =>
      client.from('reading_goals');
  static SupabaseQueryBuilder get goalProgress =>
      client.from('goal_progress');
  static SupabaseQueryBuilder get clubMeetings =>
      client.from('club_meetings');
  static SupabaseQueryBuilder get meetingRsvps =>
      client.from('meeting_rsvps');

  // Realtime channels
  static RealtimeChannel progressChannel(String clubId) =>
      client.channel('club:$clubId:progress');

  static RealtimeChannel chatChannel(String clubId) =>
      client.channel('club:$clubId:chat');

  static RealtimeChannel typingChannel(String clubId) =>
      client.channel('club:$clubId:typing');

  static RealtimeChannel notesChannel(String clubId) =>
      client.channel('club:$clubId:notes');

  static RealtimeChannel meetingsChannel(String clubId) =>
      client.channel('club:$clubId:meetings');

  // Storage
  static SupabaseStorageClient get storage => client.storage;
}
