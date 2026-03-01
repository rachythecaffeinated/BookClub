import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/club_provider.dart';

class JoinClubScreen extends ConsumerStatefulWidget {
  const JoinClubScreen({super.key});

  @override
  ConsumerState<JoinClubScreen> createState() => _JoinClubScreenState();
}

class _JoinClubScreenState extends ConsumerState<JoinClubScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    await ref.read(clubNotifierProvider.notifier).joinClubByCode(code);

    if (mounted) {
      context.go('/clubs');
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubState = ref.watch(clubNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Join Club')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the 6-character invite code shared by your club admin.',
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                hintText: 'e.g., READR7',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: clubState.isLoading ? null : _join,
              child: clubState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join Club'),
            ),
            if (clubState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  clubState.error.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
