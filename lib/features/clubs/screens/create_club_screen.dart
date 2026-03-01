import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/club_provider.dart';

class CreateClubScreen extends ConsumerStatefulWidget {
  const CreateClubScreen({super.key});

  @override
  ConsumerState<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends ConsumerState<CreateClubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    final club = await ref.read(clubNotifierProvider.notifier).createClub(
          name: _nameController.text.trim(),
          description: _descController.text.trim().isNotEmpty
              ? _descController.text.trim()
              : null,
        );

    if (mounted && club != null) {
      context.goNamed(RouteNames.clubHome, pathParameters: {'clubId': club.id});
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubState = ref.watch(clubNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Club')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  child: Icon(
                    Icons.groups,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Club Name',
                  hintText: 'e.g., The Page Turners',
                ),
                validator: (v) {
                  if (v == null ||
                      v.trim().length < AppConstants.clubNameMinLength) {
                    return 'Name must be at least ${AppConstants.clubNameMinLength} characters';
                  }
                  if (v.trim().length > AppConstants.clubNameMaxLength) {
                    return 'Name must be at most ${AppConstants.clubNameMaxLength} characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What\'s your club about?',
                ),
                maxLines: 3,
                maxLength: AppConstants.clubDescriptionMaxLength,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Private — only invited members can join',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: clubState.isLoading ? null : _create,
                child: clubState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Club'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
