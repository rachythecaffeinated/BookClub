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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ACTIVE SHELF',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/my-books'),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        booksAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
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
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.menu_book,
                          size: 40, color: Colors.grey[300]),
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
                ),
              );
            }

            // Build merged display objects with club progress data.
            final clubBooks = clubBooksAsync.valueOrNull ?? [];
            final displays = reading.map((book) {
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
                  .map((display) => _BookCard(display: display))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _BookCard extends StatelessWidget {
  final _ReadingBookDisplay display;

  const _BookCard({required this.display});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image — larger
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 60,
                height: 90,
                child: display.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: display.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppTheme.divider,
                          child: const Icon(Icons.book, size: 24),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.divider,
                          child: const Icon(Icons.book, size: 24),
                        ),
                      )
                    : Container(
                        color: AppTheme.divider,
                        child: const Icon(Icons.book, size: 24),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Title, author, progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    display.title ?? 'Untitled',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (display.author != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      display.author!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Progress bar
                  Row(
                    children: [
                      Text(
                        '${display.percentComplete.round()}%',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
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
                      const SizedBox(width: 10),
                      Text(
                        _pageDisplay(),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pageDisplay() {
    if (display.currentPage == null) return '';
    final page = display.currentPage!;
    if (display.totalPages != null && display.totalPages! > 0) {
      return '$page / ${display.totalPages} pp';
    }
    return 'pg. $page';
  }
}
