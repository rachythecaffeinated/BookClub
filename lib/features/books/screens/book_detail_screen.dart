import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/models/margin_note.dart';
import '../../../core/providers/club_provider.dart';
import '../../../core/providers/margin_note_provider.dart';

class BookDetailScreen extends ConsumerWidget {
  final String clubId;
  final String bookId;

  const BookDetailScreen({
    super.key,
    required this.clubId,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(currentBookProvider(clubId));
    final notesAsync = ref.watch(
      bookNotesProvider((clubId: clubId, bookId: bookId)),
    );
    final profilesAsync = ref.watch(clubMemberProfilesProvider(clubId));

    return Scaffold(
      appBar: AppBar(title: const Text('Book Detail')),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (book) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Book info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover image
                      SizedBox(
                        width: 100,
                        height: 150,
                        child: book?.coverUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: book!.coverUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _bookPlaceholder(),
                                  errorWidget: (_, __, ___) =>
                                      _bookPlaceholder(),
                                ),
                              )
                            : _bookPlaceholder(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book?.title ?? 'Unknown Title',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'by ${book?.author ?? 'Unknown Author'}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            if (book?.pageCount != null)
                              Text(
                                '${book!.pageCount} pages',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            if (book?.description != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                book!.description!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Margin notes section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Margin Notes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: () => context.pushNamed(
                      RouteNames.createNote,
                      pathParameters: {'clubId': clubId},
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Leave a Note'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Notes list
              notesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading notes: $e'),
                data: (notes) {
                  if (notes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(Icons.sticky_note_2_outlined,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No margin notes yet',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Notes will appear as you read further',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final profiles = profilesAsync.valueOrNull ?? {};

                  return Column(
                    children: notes.map((note) {
                      final profile = profiles[note.userId];
                      return _NoteCard(
                        note: note,
                        authorName: profile?.displayName ?? 'Unknown',
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bookPlaceholder() {
    return Container(
      width: 100,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.book, size: 40, color: Colors.grey[400]),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final MarginNote note;
  final String authorName;

  const _NoteCard({required this.note, required this.authorName});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: author + page + visibility
            Row(
              children: [
                Text(
                  authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (note.pageNumber != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'pg. ${note.pageNumber}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
                const Spacer(),
                if (note.visibility == NoteVisibility.private_)
                  Icon(Icons.lock, size: 14, color: Colors.grey[400]),
              ],
            ),
            // Quote
            if (note.quoteText != null && note.quoteText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  note.quoteText!,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            // Note text
            const SizedBox(height: 8),
            Text(
              note.noteText,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
