import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/supabase_service.dart';

/// Provides the current Supabase auth state as a stream.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.auth.onAuthStateChange;
});

/// Provides the current authenticated user (or null).
final currentUserProvider = Provider<User?>((ref) {
  return SupabaseService.auth.currentUser;
});

/// Provides the current user's profile from the users table.
final userProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  final userId = SupabaseService.currentUserId;
  if (userId == null) return null;

  final response =
      await SupabaseService.users.select().eq('id', userId).maybeSingle();

  if (response == null) return null;
  return UserProfile.fromJson(response);
});

/// Auth actions notifier for sign up, sign in, sign out.
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await SupabaseService.auth.signUp(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await SupabaseService.auth.signInWithOAuth(OAuthProvider.google);
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await SupabaseService.auth.signInWithOAuth(OAuthProvider.apple);
    });
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await SupabaseService.auth.resetPasswordForEmail(email);
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await SupabaseService.auth.signOut();
    });
  }

  Future<void> createUserProfile({
    required String displayName,
    String? avatarUrl,
    String? timezone,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      await SupabaseService.users.upsert({
        'id': userId,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'timezone': timezone ?? 'UTC',
      });
    });
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier();
});
