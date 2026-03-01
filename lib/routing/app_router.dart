import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/route_names.dart';
import '../core/services/supabase_service.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/log_in_screen.dart';
import '../features/auth/screens/profile_setup_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/books/screens/book_detail_screen.dart';
import '../features/books/screens/scan_book_screen.dart';
import '../features/books/screens/search_book_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/clubs/screens/club_home_screen.dart';
import '../features/clubs/screens/club_settings_screen.dart';
import '../features/clubs/screens/create_club_screen.dart';
import '../features/clubs/screens/invite_members_screen.dart';
import '../features/clubs/screens/join_club_screen.dart';
import '../features/margin_notes/screens/create_note_screen.dart';
import '../features/meetings/screens/meeting_detail_screen.dart';
import '../features/meetings/screens/schedule_meeting_screen.dart';
import '../features/personal_library/screens/my_books_screen.dart';
import '../features/personal_library/screens/reading_goals_screen.dart';
import '../features/personal_library/screens/stats_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/progress/screens/update_progress_screen.dart';
import 'shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = SupabaseService.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/' ||
          state.matchedLocation == '/sign-up' ||
          state.matchedLocation == '/log-in' ||
          state.matchedLocation == '/forgot-password';

      if (!isAuthenticated && !isAuthRoute) return '/';
      if (isAuthenticated && isAuthRoute) return '/clubs';
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/',
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        name: RouteNames.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/log-in',
        name: RouteNames.logIn,
        builder: (context, state) => const LogInScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: RouteNames.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/clubs',
            name: RouteNames.clubs,
            builder: (context, state) => const ClubsListPlaceholder(),
            routes: [
              GoRoute(
                path: 'create',
                name: RouteNames.createClub,
                builder: (context, state) => const CreateClubScreen(),
              ),
              GoRoute(
                path: 'join',
                name: RouteNames.joinClub,
                builder: (context, state) => const JoinClubScreen(),
              ),
              GoRoute(
                path: ':clubId',
                name: RouteNames.clubHome,
                builder: (context, state) => ClubHomeScreen(
                  clubId: state.pathParameters['clubId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'settings',
                    name: RouteNames.clubSettings,
                    builder: (context, state) => ClubSettingsScreen(
                      clubId: state.pathParameters['clubId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'invite',
                    name: RouteNames.inviteMembers,
                    builder: (context, state) => InviteMembersScreen(
                      clubId: state.pathParameters['clubId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'chat',
                    name: RouteNames.chat,
                    builder: (context, state) => ChatScreen(
                      clubId: state.pathParameters['clubId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'progress',
                    name: RouteNames.updateProgress,
                    builder: (context, state) => UpdateProgressScreen(
                      clubId: state.pathParameters['clubId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'book/:bookId',
                    name: RouteNames.bookDetail,
                    builder: (context, state) => BookDetailScreen(
                      clubId: state.pathParameters['clubId']!,
                      bookId: state.pathParameters['bookId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'note/create',
                    name: RouteNames.createNote,
                    builder: (context, state) => CreateNoteScreen(
                      clubId: state.pathParameters['clubId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'scan',
                    name: RouteNames.scanBook,
                    builder: (context, state) => ScanBookScreen(
                      clubId: state.pathParameters['clubId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'search-book',
                    name: RouteNames.searchBook,
                    builder: (context, state) => SearchBookScreen(
                      clubId: state.pathParameters['clubId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'meeting/schedule',
                    name: RouteNames.scheduleMeeting,
                    builder: (context, state) => ScheduleMeetingScreen(
                      clubId: state.pathParameters['clubId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'meeting/:meetingId',
                    name: RouteNames.meetingDetail,
                    builder: (context, state) => MeetingDetailScreen(
                      clubId: state.pathParameters['clubId']!,
                      meetingId: state.pathParameters['meetingId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/my-books',
            name: RouteNames.myBooks,
            builder: (context, state) => const MyBooksScreen(),
          ),
          GoRoute(
            path: '/stats',
            name: RouteNames.stats,
            builder: (context, state) => const StatsScreen(),
            routes: [
              GoRoute(
                path: 'goals',
                name: RouteNames.readingGoals,
                builder: (context, state) => const ReadingGoalsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Placeholder widget for the clubs list tab.
class ClubsListPlaceholder extends StatelessWidget {
  const ClubsListPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Clubs')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey[400]),
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
    );
  }
}
