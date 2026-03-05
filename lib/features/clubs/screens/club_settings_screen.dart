import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/club.dart';
import '../../../core/providers/club_provider.dart';
import '../../../core/providers/progress_provider.dart';

class ClubSettingsScreen extends ConsumerWidget {
  final String clubId;

  const ClubSettingsScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(clubProvider(clubId));
    final memberAsync = ref.watch(currentUserMemberProvider(clubId));
    final isAdmin = memberAsync.valueOrNull?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Club Settings')),
      body: clubAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (club) {
          if (club == null) {
            return const Center(child: Text('Club not found'));
          }

          return ListView(
            children: [
              // Club avatar & background preview
              _ClubImageHeader(
                avatarUrl: club.avatarUrl,
                backgroundUrl: club.backgroundUrl,
                clubName: club.name,
              ),

              if (isAdmin) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'APPEARANCE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: const Text('Change Club Icon'),
                  subtitle: const Text('Shown in club lists and chat'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickAndUploadImage(
                    context: context,
                    ref: ref,
                    type: _ImageType.avatar,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.wallpaper),
                  title: const Text('Change Background'),
                  subtitle: const Text('Header image for the club'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickAndUploadImage(
                    context: context,
                    ref: ref,
                    type: _ImageType.background,
                  ),
                ),
                const Divider(),
              ],

              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Club Name & Description'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditClubDialog(context, ref, club),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Change Current Book'),
                subtitle:
                    const Text('Clears current book and resets all progress'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _confirmChangeBook(context, ref),
              ),
              if (isAdmin) ...[
                const Divider(),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red[400]),
                  title: Text(
                    'Delete Club',
                    style: TextStyle(color: Colors.red[400]),
                  ),
                  onTap: () => _confirmDeleteClub(context, ref),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _pickAndUploadImage({
    required BuildContext context,
    required WidgetRef ref,
    required _ImageType type,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(
                  context: context,
                  ref: ref,
                  source: ImageSource.gallery,
                  type: type,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(
                  context: context,
                  ref: ref,
                  source: ImageSource.camera,
                  type: type,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage({
    required BuildContext context,
    required WidgetRef ref,
    required ImageSource source,
    required _ImageType type,
  }) async {
    final picker = ImagePicker();
    final maxWidth = type == _ImageType.avatar ? 512.0 : 1280.0;
    final maxHeight = type == _ImageType.avatar ? 512.0 : 720.0;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: 80,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final notifier = ref.read(clubNotifierProvider.notifier);

    if (type == _ImageType.avatar) {
      await notifier.updateClubAvatar(clubId: clubId, imageFile: file);
    } else {
      await notifier.updateClubBackground(clubId: clubId, imageFile: file);
    }

    // Refresh the club data so the UI updates.
    ref.invalidate(clubProvider(clubId));
    ref.invalidate(userClubsProvider);

    if (context.mounted) {
      final label = type == _ImageType.avatar ? 'Club icon' : 'Background';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label updated!')),
      );
    }
  }

  void _showEditClubDialog(BuildContext context, WidgetRef ref, Club club) {
    final nameController = TextEditingController(text: club.name);
    final descController = TextEditingController(text: club.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Club'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Club Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(clubNotifierProvider.notifier).updateClub(
                    clubId: clubId,
                    name: nameController.text,
                    description: descController.text,
                  );
              ref.invalidate(clubProvider(clubId));
              ref.invalidate(userClubsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Club updated!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClub(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Club?'),
        content: const Text(
          'This will permanently delete this club and all its data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(clubNotifierProvider.notifier)
                  .deleteClub(clubId: clubId);
              ref.invalidate(userClubsProvider);
              if (context.mounted) {
                context.go('/clubs');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmChangeBook(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Current Book?'),
        content: const Text(
          'This will clear the current book and reset all member progress. '
          'You can then choose a new book.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(clubNotifierProvider.notifier)
                  .clearCurrentBook(clubId: clubId);
              ref.invalidate(clubProvider(clubId));
              ref.invalidate(currentBookProvider(clubId));
              ref.invalidate(clubProgressProvider(clubId));
              ref.invalidate(myProgressProvider(clubId));
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text('Clear Book'),
          ),
        ],
      ),
    );
  }
}

enum _ImageType { avatar, background }

class _ClubImageHeader extends StatelessWidget {
  final String? avatarUrl;
  final String? backgroundUrl;
  final String clubName;

  const _ClubImageHeader({
    this.avatarUrl,
    this.backgroundUrl,
    required this.clubName,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background
          Positioned.fill(
            child: backgroundUrl != null
                ? Image.network(
                    backgroundUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _backgroundPlaceholder(context),
                  )
                : _backgroundPlaceholder(context),
          ),
          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          // Avatar
          Positioned(
            bottom: 12,
            left: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Text(
                          clubName.isNotEmpty
                              ? clubName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  clubName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black54),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      child: Center(
        child: Icon(
          Icons.photo,
          size: 48,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
