abstract class AppConstants {
  // Club limits
  static const int maxClubsPerUser = 5;
  static const int maxMembersPerClub = 25;

  // Text limits
  static const int displayNameMinLength = 2;
  static const int displayNameMaxLength = 30;
  static const int clubNameMinLength = 3;
  static const int clubNameMaxLength = 50;
  static const int clubDescriptionMaxLength = 200;
  static const int marginNoteMaxLength = 500;
  static const int quoteMaxLength = 300;
  static const int noteReplyMaxLength = 280;
  static const int chatMessageMaxLength = 1000;
  static const int meetingDescriptionMaxLength = 500;

  // Invite
  static const int inviteCodeLength = 6;
  static const int inviteExpirationDays = 7;

  // Chat
  static const int chatPageSize = 50;
  static const int typingTimeoutSeconds = 3;

  // Streaks
  static const int inactiveDaysThreshold = 7;

  // Reading formats
  static const List<String> clubReadingFormats = [
    'same_edition',
    'diff_edition',
    'kindle',
    'audiobook',
    'other',
  ];

  static const List<String> personalReadingFormats = [
    'physical',
    'kindle',
    'audiobook',
    'ebook',
    'other',
  ];

  // Reaction emojis
  static const List<String> noteReactionEmojis = [
    '\u{1F4A1}', // 💡
    '\u{2764}\u{FE0F}', // ❤️
    '\u{1F602}', // 😂
    '\u{1F914}', // 🤔
    '\u{1F44F}', // 👏
  ];
}
