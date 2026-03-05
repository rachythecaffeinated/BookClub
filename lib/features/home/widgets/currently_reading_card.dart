import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/personal_book.dart';
import '../../../core/providers/personal_library_provider.dart';

/// Merged view of a currently-reading book with the best available progress.
class _ReadingBookDisplay {
  final String? title;
  final String? author;
  final String? coverUrl;
  final int? currentPage;
  final int? totalPages;
  final double percentComplete;

  const _ReadingBookDisplay({
    this.title,
    this.author,
    this.coverUrl,
    this.currentPage,
    this.totalPages,
    required this.percentComplete,
  });
}

class CurrentlyReadingCard extends ConsumerWidget {
  const CurrentlyReadingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(personalBooksProvider);
    final clubBooksAsync = ref.watch(clubCurrentBooksProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currently Reading',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            booksAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const Text('Unable to load books'),
              data: (books) {
                final reading = books
                    .where((b) => b.shelf == Shelf.reading)
                    .take(2)
                    .toList();

                if (reading.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(Icons.menu_book,
                            size: 32, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No books in progress',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/my-books'),
                          child: const Text('Start reading a book'),
                        ),
                      ],
                    ),
                  );
                }

                // Build merged display objects with club progress data.
                final clubBooks = clubBooksAsync.valueOrNull ?? [];
                final displays = reading.map((book) {
                  // Try to find matching club progress by book ID.
                  final clubMatch = clubBooks
                      .where((cb) =>
                          cb.sourceBookId == book.bookId ||
                          cb.book.id == book.bookId)
                      .firstOrNull;

                  final clubProgress = clubMatch?.myProgress;
                  final currentPage =
                      clubProgress?.currentPage ?? book.currentPage;
                  final percent = clubProgress != null
                      ? clubProgress.percentComplete
                      : book.percentComplete;
                  final totalPages = clubMatch?.book.pageCount;

                  return _ReadingBookDisplay(
                    title: book.title,
                    author: book.author,
                    coverUrl: book.coverUrl,
                    currentPage: currentPage,
                    totalPages: totalPages,
                    percentComplete: percent,
                  );
                }).toList();

                return Column(
                  children: displays
                      .map((display) => _BookRow(display: display))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  final _ReadingBookDisplay display;

  const _BookRow({required this.display});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 40,
              height: 60,
              child: display.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: display.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppTheme.divider,
                        child: const Icon(Icons.book, size: 20),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.divider,
                        child: const Icon(Icons.book, size: 20),
                      ),
                    )
                  : Container(
                      color: AppTheme.divider,
                      child: const Icon(Icons.book, size: 20),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Title, author, progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  display.title ?? 'Untitled',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (display.author != null)
                  Text(
                    display.author!,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (display.currentPage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _pageDisplay(),
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (display.percentComplete / 100.0)
                              .clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppTheme.divider,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${display.percentComplete.round()}%',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pageDisplay() {
    final page = display.currentPage!;
    if (display.totalPages != null && display.totalPages! > 0) {
      return 'pg. $page of ${display.totalPages}';
    }
    return 'pg. $page';
  }
}
