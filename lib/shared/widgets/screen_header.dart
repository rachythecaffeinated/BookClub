import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/providers/auth_provider.dart';

/// Reusable screen header matching the design pattern:
/// Small uppercase section label + large bold title with accent word in purple italic.
/// Includes notification bell + user avatar in the top right.
class ScreenHeader extends ConsumerWidget {
  /// Small uppercase label (e.g. "COMMUNITY HUB")
  final String sectionLabel;

  /// First part of the title (e.g. "My ")
  final String titlePrefix;

  /// Accented part of the title in purple italic (e.g. "Clubs")
  final String titleAccent;

  const ScreenHeader({
    super.key,
    required this.sectionLabel,
    required this.titlePrefix,
    required this.titleAccent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title area
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sectionLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: titlePrefix,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: titleAccent,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.primary,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Bell + Avatar
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.divider, width: 1),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  profileAsync.when(
                    loading: () => _buildAvatarPlaceholder(null),
                    error: (_, __) => _buildAvatarPlaceholder(null),
                    data: (profile) => _buildAvatarPlaceholder(
                      profile?.displayName,
                      avatarUrl: profile?.avatarUrl,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String? name, {String? avatarUrl}) {
    final initials = _getInitials(name);
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary,
      ),
      child: avatarUrl != null
          ? ClipOval(
              child: Image.network(
                avatarUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
