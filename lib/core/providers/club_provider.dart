import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/club.dart';
import '../models/club_member.dart';
import '../services/supabase_service.dart';

/// Provides the list of clubs the current user belongs to.
final userClubsProvider = FutureProvider.autoDispose<List<Club>>((ref) async {
  final userId = SupabaseService.currentUserId;
  if (userId == null) return [];

  final memberRows = await SupabaseService.clubMembers
      .select('club_id')
      .eq('user_id', userId)
      .eq('status', 'accepted');

  final clubIds =
      (memberRows as List).map((row) => row['club_id'] as String).toList();

  if (clubIds.isEmpty) return [];

  final clubRows =
      await SupabaseService.clubs.select().inFilter('id', clubIds);

  return (clubRows as List).map((row) => Club.fromJson(row)).toList();
});

/// Provides a single club by ID.
final clubProvider =
    FutureProvider.autoDispose.family<Club?, String>((ref, clubId) async {
  final response =
      await SupabaseService.clubs.select().eq('id', clubId).maybeSingle();

  if (response == null) return null;
  return Club.fromJson(response);
});

/// Provides members for a given club.
final clubMembersProvider = FutureProvider.autoDispose
    .family<List<ClubMember>, String>((ref, clubId) async {
  final response = await SupabaseService.clubMembers
      .select()
      .eq('club_id', clubId)
      .eq('status', 'accepted');

  return (response as List).map((row) => ClubMember.fromJson(row)).toList();
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
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      final inviteCode = _generateInviteCode();

      final response = await SupabaseService.clubs
          .insert({
            'name': name,
            'description': description,
            'avatar_url': avatarUrl,
            'invite_code': inviteCode,
            'created_by': userId,
            'invite_expires_at': DateTime.now()
                .add(const Duration(days: 7))
                .toIso8601String(),
          })
          .select()
          .single();

      created = Club.fromJson(response);

      // Add creator as admin member
      await SupabaseService.clubMembers.insert({
        'club_id': created!.id,
        'user_id': userId,
        'role': 'admin',
        'status': 'accepted',
        'joined_at': DateTime.now().toIso8601String(),
      });
    });
    return created;
  }

  Future<void> joinClubByCode(String code) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('Not authenticated');

      final clubRow = await SupabaseService.clubs
          .select()
          .eq('invite_code', code.toUpperCase())
          .maybeSingle();

      if (clubRow == null) throw Exception('Invalid invite code');

      final club = Club.fromJson(clubRow);

      if (club.inviteExpiresAt != null &&
          club.inviteExpiresAt!.isBefore(DateTime.now())) {
        throw Exception('Invite code has expired');
      }

      await SupabaseService.clubMembers.insert({
        'club_id': club.id,
        'user_id': userId,
        'role': 'member',
        'status': 'accepted',
        'joined_at': DateTime.now().toIso8601String(),
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
