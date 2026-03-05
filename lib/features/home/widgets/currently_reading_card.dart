import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/personal_book.dart';
import '../../../core/providers/personal_library_provider.dart';

class CurrentlyReadingCard extends ConsumerWidget {
  const CurrentlyReadingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(personalBooksProvider);

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

                return Column(
                  children: reading
                      .map((book) => _BookRow(book: book))
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
  final PersonalBook book;

  const _BookRow({required this.book});

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
              child: book.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: book.coverUrl!,
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
                  book.title ?? 'Untitled',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (book.author != null)
                  Text(
                    book.author!,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (book.percentComplete / 100.0).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppTheme.divider,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${book.percentComplete.round()}%',
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
}
