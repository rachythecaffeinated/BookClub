import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../models/club.dart';
import '../models/club_member.dart';
import '../models/user_profile.dart';
import '../services/firebase_service.dart';

/// Provides the list of clubs the current user belongs to.
final userClubsProvider = FutureProvider.autoDispose<List<Club>>((ref) async {
  final userId = FirebaseService.currentUserId;
  if (userId == null) return [];

  final userDoc = await FirebaseService.users.doc(userId).get();
  if (!userDoc.exists) return [];

  final clubIds = List<String>.from(userDoc.data()?['club_ids'] ?? []);
  if (clubIds.isEmpty) return [];

  // Firestore whereIn supports up to 30 items — fine for a book club app.
  final snapshot = await FirebaseService.clubs
      .where(FieldPath.documentId, whereIn: clubIds)
      .get();

  return snapshot.docs
      .map((doc) => Club.fromJson(FirebaseService.docToJson(doc)))
      .toList();
});

/// Provides a single club by ID.
final clubProvider =
    FutureProvider.autoDispose.family<Club?, String>((ref, clubId) async {
  final doc = await FirebaseService.clubs.doc(clubId).get();
  if (!doc.exists) return null;
  return Club.fromJson(FirebaseService.docToJson(doc));
});

/// Provides members for a given club.
final clubMembersProvider = FutureProvider.autoDispose
    .family<List<ClubMember>, String>((ref, clubId) async {
  final snapshot = await FirebaseService.clubMembers(clubId)
      .where('status', isEqualTo: 'accepted')
      .get();

  return snapshot.docs
      .map((doc) => ClubMember.fromJson(
            FirebaseService.docToJson(doc, extra: {'club_id': clubId}),
          ),)
      .toList();
});

/// Provides user profiles for club members, keyed by user ID.
final clubMemberProfilesProvider = FutureProvider.autoDispose
    .family<Map<String, UserProfile>, String>((ref, clubId) async {
  final members = await ref.watch(clubMembersProvider(clubId).future);
  if (members.isEmpty) return {};

  final userIds = members.map((m) => m.userId).toList();
  final snapshot = await FirebaseService.users
      .where(FieldPath.documentId, whereIn: userIds)
      .get();

  return {
    for (final doc in snapshot.docs)
      doc.id: UserProfile.fromJson(FirebaseService.docToJson(doc)),
  };
});

/// Provides the current user's ClubMember record for a given club.
final currentUserMemberProvider = FutureProvider.autoDispose
    .family<ClubMember?, String>((ref, clubId) async {
  final userId = FirebaseService.currentUserId;
  if (userId == null) return null;

  final doc = await FirebaseService.clubMembers(clubId).doc(userId).get();
  if (!doc.exists) return null;
  return ClubMember.fromJson(
    FirebaseService.docToJson(doc, extra: {'club_id': clubId}),
  );
});

/// Provides the current book for a club (from the club's books subcollection).
final currentBookProvider = FutureProvider.autoDispose
    .family<Book?, String>((ref, clubId) async {
  final club = await ref.watch(clubProvider(clubId).future);
  if (club == null || club.currentBookId == null) return null;

  final doc =
      await FirebaseService.clubBooks(clubId).doc(club.currentBookId).get();
  if (!doc.exists) return null;
  return Book.fromJson(FirebaseService.docToJson(doc));
});

/// Club actions notifier.
class ClubNotifier extends StateNotifier<AsyncValue<void>> {
  ClubNotifier() : super(const AsyncValue.data(null));

  Future<Club?> createClub({
    required String name,
    String? description,
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();
    Club? created;
    state = await AsyncValue.guard(() async {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      final inviteCode = _generateInviteCode();
      final clubRef = FirebaseService.clubs.doc();

      final clubData = {
        'name': name,
        'description': description,
        'avatar_url': avatarUrl,
        'invite_code': inviteCode,
        'created_by': userId,
        'invite_expires_at': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'created_at': FieldValue.serverTimestamp(),
        'member_count': 1,
      };

      // Use a batch write for atomicity.
      final batch = FirebaseService.firestore.batch();
      batch.set(clubRef, clubData);
      batch.set(FirebaseService.clubMembers(clubRef.id).doc(userId), {
        'user_id': userId,
        'role': 'admin',
        'status': 'accepted',
        'joined_at': FieldValue.serverTimestamp(),
      });
      batch.update(FirebaseService.users.doc(userId), {
        'club_ids': FieldValue.arrayUnion([clubRef.id]),
      });
      // Write invite code to the invites collection for non-member lookup.
      batch.set(FirebaseService.invites.doc(inviteCode), {
        'club_id': clubRef.id,
        'expires_at': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
      });
      await batch.commit();

      // Read back the created club for the return value.
      final clubDoc = await clubRef.get();
      created = Club.fromJson(FirebaseService.docToJson(clubDoc));
    });
    return created;
  }

  Future<void> joinClubByCode(String code) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      // Look up the invite code in the invites collection.
      final inviteDoc =
          await FirebaseService.invites.doc(code.toUpperCase()).get();

      if (!inviteDoc.exists) throw Exception('Invalid invite code');

      final inviteData = inviteDoc.data()!;
      final expiresAt = inviteData['expires_at'] as Timestamp?;
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        throw Exception('Invite code has expired');
      }

      final clubId = inviteData['club_id'] as String;

      // Check if user is already a member.
      final existingMember =
          await FirebaseService.clubMembers(clubId).doc(userId).get();
      if (existingMember.exists) {
        throw Exception('You are already a member of this club');
      }

      // Batch: add member + update denormalized arrays.
      final batch = FirebaseService.firestore.batch();
      batch.set(FirebaseService.clubMembers(clubId).doc(userId), {
        'user_id': userId,
        'role': 'member',
        'status': 'accepted',
        'joined_at': FieldValue.serverTimestamp(),
      });
      batch.update(FirebaseService.users.doc(userId), {
        'club_ids': FieldValue.arrayUnion([clubId]),
      });
      batch.update(FirebaseService.clubs.doc(clubId), {
        'member_count': FieldValue.increment(1),
      });
      await batch.commit();
    });
  }

  Future<void> setCurrentBook({
    required String clubId,
    required Book book,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Save the book to the club's books subcollection.
      final bookRef = FirebaseService.clubBooks(clubId).doc();
      final bookData = {
        ...book.toJson(),
        'created_at': FieldValue.serverTimestamp(),
      };
      final batch = FirebaseService.firestore.batch();
      batch.set(bookRef, bookData);
      batch.update(FirebaseService.clubs.doc(clubId), {
        'current_book_id': bookRef.id,
      });
      await batch.commit();
    });
  }

  Future<void> clearCurrentBook({required String clubId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Clear the current book reference on the club doc.
      await FirebaseService.clubs.doc(clubId).update({
        'current_book_id': FieldValue.delete(),
      });

      // Delete all progress docs for this club.
      final progressDocs =
          await FirebaseService.clubProgress(clubId).get();
      final batch = FirebaseService.firestore.batch();
      for (final doc in progressDocs.docs) {
        batch.delete(doc.reference);
      }
      if (progressDocs.docs.isNotEmpty) {
        await batch.commit();
      }
    });
  }

  Future<void> updateBookPageCount({
    required String clubId,
    required String bookId,
    required int pageCount,
  }) async {
    await FirebaseService.clubBooks(clubId).doc(bookId).update({
      'page_count': pageCount,
    });
  }

  /// Upload an image to Firebase Storage and return the download URL.
  Future<String> _uploadClubImage({
    required String clubId,
    required File imageFile,
    required String folder,
  }) async {
    final ext = imageFile.path.split('.').last;
    final ref = FirebaseService.storage
        .ref()
        .child('clubs/$clubId/$folder.$ext');
    await ref.putFile(imageFile);
    return ref.getDownloadURL();
  }

  /// Update the club's avatar image.
  Future<void> updateClubAvatar({
    required String clubId,
    required File imageFile,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final url = await _uploadClubImage(
        clubId: clubId,
        imageFile: imageFile,
        folder: 'avatar',
      );
      await FirebaseService.clubs.doc(clubId).update({
        'avatar_url': url,
      });
    });
  }

  /// Update the club's background image.
  Future<void> updateClubBackground({
    required String clubId,
    required File imageFile,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final url = await _uploadClubImage(
        clubId: clubId,
        imageFile: imageFile,
        folder: 'background',
      );
      await FirebaseService.clubs.doc(clubId).update({
        'background_url': url,
      });
    });
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

final clubNotifierProvider =
    StateNotifierProvider<ClubNotifier, AsyncValue<void>>((ref) {
  return ClubNotifier();
});
