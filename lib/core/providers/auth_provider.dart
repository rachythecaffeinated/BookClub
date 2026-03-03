import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/user_profile.dart';
import '../services/firebase_service.dart';

/// Provides the current Firebase auth state as a stream.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.auth.authStateChanges();
});

/// Provides the current authenticated user (or null).
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return FirebaseService.auth.currentUser;
});

/// Provides the current user's profile from the users collection.
final userProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  final userId = FirebaseService.currentUserId;
  if (userId == null) return null;

  final doc = await FirebaseService.users.doc(userId).get();
  if (!doc.exists) return null;
  return UserProfile.fromJson(FirebaseService.docToJson(doc));
});

/// Maps Firebase Auth error codes to user-friendly messages.
String friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'An authentication error occurred.';
    }
  }
  final msg = error.toString();
  if (msg.contains('Google sign-in cancelled') ||
      msg.contains('SignInWithAppleAuthorizationError')) {
    return 'Sign-in was cancelled.';
  }
  return 'Something went wrong. Please try again.';
}

/// Auth actions notifier for sign up, sign in, sign out.
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.auth.createUserWithEmailAndPassword(
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
      await FirebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw Exception('Google sign-in cancelled');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseService.auth.signInWithCredential(credential);
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final rawNonce = _generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      await FirebaseService.auth.signInWithCredential(oauthCredential);
    });
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.auth.sendPasswordResetEmail(email: email);
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await GoogleSignIn().signOut();
      await FirebaseService.auth.signOut();
    });
  }

  Future<void> createUserProfile({
    required String displayName,
    String? avatarUrl,
    String? timezone,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      await FirebaseService.users.doc(userId).set({
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'timezone': timezone ?? 'UTC',
        'created_at': FieldValue.serverTimestamp(),
        'club_ids': [],
      }, SetOptions(merge: true));
    });
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier();
});
