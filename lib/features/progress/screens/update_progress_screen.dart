import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/progress_provider.dart';

class UpdateProgressScreen extends ConsumerStatefulWidget {
  final String clubId;

  const UpdateProgressScreen({super.key, required this.clubId});

  @override
  ConsumerState<UpdateProgressScreen> createState() =>
      _UpdateProgressScreenState();
}

class _UpdateProgressScreenState extends ConsumerState<UpdateProgressScreen> {
  final _pageController = TextEditingController();
  double _percentSlider = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressState = ref.watch(progressNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Update Progress')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What page are you on?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // Page number input
            TextFormField(
              controller: _pageController,
              decoration: const InputDecoration(
                labelText: 'Current Page',
                hintText: 'e.g., 187',
                prefixIcon: Icon(Icons.bookmark_outline),
                suffixText: 'of ---',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                // TODO: Calculate percentage based on total pages
              },
            ),
            const SizedBox(height: 24),

            // Percentage display
            Center(
              child: Text(
                '${_percentSlider.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Slider(
              value: _percentSlider,
              max: 100,
              divisions: 100,
              label: '${_percentSlider.toStringAsFixed(0)}%',
              onChanged: (value) => setState(() => _percentSlider = value),
            ),
            const SizedBox(height: 8),
            Text(
              'Or use the slider for manual percentage input',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: progressState.isLoading
                  ? null
                  : () {
                      // TODO: Save progress with correct book_id
                      context.pop();
                    },
              child: progressState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Progress'),
            ),
          ],
        ),
      ),
    );
  }
}
