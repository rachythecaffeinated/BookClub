import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/club_provider.dart';
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
  final _totalPagesController = TextEditingController();
  double _percentSlider = 0;
  bool _initialized = false;

  @override
  void dispose() {
    _pageController.dispose();
    _totalPagesController.dispose();
    super.dispose();
  }

  void _initFromExisting(int? bookPageCount) {
    if (_initialized) return;
    _initialized = true;

    if (bookPageCount != null) {
      _totalPagesController.text = bookPageCount.toString();
    }

    final existingProgress =
        ref.read(myProgressProvider(widget.clubId)).valueOrNull;
    if (existingProgress != null) {
      _percentSlider = existingProgress.percentComplete;
      if (existingProgress.currentPage != null) {
        _pageController.text = existingProgress.currentPage.toString();
      }
    }
  }

  int? get _totalPages => int.tryParse(_totalPagesController.text.trim());

  void _onPageChanged(String value) {
    final total = _totalPages;
    if (value.isEmpty || total == null || total == 0) return;
    final page = int.tryParse(value);
    if (page == null) return;
    setState(() {
      _percentSlider =
          ((page / total) * 100).clamp(0, 100).roundToDouble();
    });
  }

  void _onTotalPagesChanged(String value) {
    // Recalculate percent from current page if we have one.
    final page = int.tryParse(_pageController.text.trim());
    final total = int.tryParse(value);
    if (page != null && total != null && total > 0) {
      setState(() {
        _percentSlider =
            ((page / total) * 100).clamp(0, 100).roundToDouble();
      });
    }
  }

  Future<void> _save() async {
    final book = ref.read(currentBookProvider(widget.clubId)).valueOrNull;
    if (book == null) return;

    final page = int.tryParse(_pageController.text.trim());
    final enteredTotal = _totalPages;

    // If user entered a total page count that differs from the book's,
    // update the book document.
    if (enteredTotal != null && enteredTotal != book.pageCount) {
      await ref.read(clubNotifierProvider.notifier).updateBookPageCount(
            clubId: widget.clubId,
            bookId: book.id,
            pageCount: enteredTotal,
          );
      ref.invalidate(currentBookProvider(widget.clubId));
    }

    await ref.read(progressNotifierProvider.notifier).updateProgress(
          clubId: widget.clubId,
          bookId: book.id,
          currentPage: page,
          percentComplete: _percentSlider,
        );

    if (mounted && !ref.read(progressNotifierProvider).hasError) {
      ref.invalidate(clubProgressProvider(widget.clubId));
      ref.invalidate(myProgressProvider(widget.clubId));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(currentBookProvider(widget.clubId));
    final myProgressAsync = ref.watch(myProgressProvider(widget.clubId));
    final progressState = ref.watch(progressNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Update Progress')),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (book) {
          if (book == null) {
            return const Center(child: Text('No book selected'));
          }

          // Initialize once book + progress are loaded.
          myProgressAsync.whenData((_) => _initFromExisting(book.pageCount));

          final hasTotalPages = _totalPages != null && _totalPages! > 0;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Book title
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  book.author,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),

                // Total pages (always shown so user can correct it)
                TextFormField(
                  controller: _totalPagesController,
                  decoration: InputDecoration(
                    labelText: 'Total pages in your edition',
                    hintText: 'e.g., 384',
                    prefixIcon: const Icon(Icons.menu_book),
                    helperText: book.pageCount == null
                        ? 'Needed for page-based progress tracking'
                        : null,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: _onTotalPagesChanged,
                ),
                const SizedBox(height: 16),

                // Page number input
                TextFormField(
                  controller: _pageController,
                  decoration: InputDecoration(
                    labelText: 'Current Page',
                    hintText: 'e.g., 187',
                    prefixIcon: const Icon(Icons.bookmark_outline),
                    suffixText: hasTotalPages ? 'of ${_totalPages}' : null,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: _onPageChanged,
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
                  onChanged: (value) {
                    setState(() => _percentSlider = value);
                    if (hasTotalPages) {
                      final page = (value / 100 * _totalPages!).round();
                      _pageController.text = page.toString();
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  hasTotalPages
                      ? 'Enter a page number or use the slider'
                      : 'Enter total pages above, or use the slider',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),

                if (progressState.hasError) ...[
                  const SizedBox(height: 16),
                  Text(
                    progressState.error.toString(),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],

                const Spacer(),

                ElevatedButton(
                  onPressed: progressState.isLoading ? null : _save,
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
          );
        },
      ),
    );
  }
}
