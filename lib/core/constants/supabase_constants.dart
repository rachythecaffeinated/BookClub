abstract class SupabaseConstants {
  // TODO: Replace with your Supabase project credentials.
  // For production, load these from environment variables or dart-define.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here',
  );
  static const String googleBooksApiKey = String.fromEnvironment(
    'GOOGLE_BOOKS_API_KEY',
    defaultValue: '',
  );
}
