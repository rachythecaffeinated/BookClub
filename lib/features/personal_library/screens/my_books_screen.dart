import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/book.dart';
import '../../../core/models/personal_book.dart';
import '../../../core/providers/personal_library_provider.dart';
import '../../../core/services/google_books_service.dart';

typedef _BookMatch = ({PersonalBook? personalBook, bool isOwned, bool isRead, bool isReading});

class MyBooksScreen extends ConsumerWidget {
  const MyBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(personalBooksProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Books'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Reading'),
              Tab(text: 'Want to Read'),
              Tab(text: 'My Library'),
              Tab(text: 'Finished'),
            ],
          ),
        ),
        body: booksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (books) {
            final reading =
                books.where((b) => b.shelf == Shelf.reading).toList();
            final wantToRead =
                books.where((b) => b.shelf == Shelf.wantToRead).toList();
            final owned =
                books.where((b) => b.isOwned).toList();
            final finished =
                books.where((b) => b.shelf == Shelf.finished).toList();

            return TabBarView(
              children: [
                _ReadingTab(personalReading: reading, allPersonalBooks: books),
                _BookShelf(
                  books: wantToRead,
                  emptyIcon: Icons.bookmark_border,
                  emptyMessage: 'Your TBR pile is empty',
                  emptySubtitle: 'Add books you want to read next',
                ),
                _LibraryShelf(books: owned),
                _BookShelf(
                  books: finished,
                  emptyIcon: Icons.done_all,
                  emptyMessage: 'No finished books yet',
                  emptySubtitle: 'Completed books will appear here',
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddBookSheet(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddBookSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => _AddBookSheet(
          scrollController: scrollController,
          onBookSelected: (book, shelf, {bool isOwned = false}) async {
            Navigator.pop(context);
            await ref
                .read(personalLibraryNotifierProvider.notifier)
                .addBook(book: book, shelf: shelf, isOwned: isOwned);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added "${book.title}" to your shelf')),
              );
            }
          },
        ),
      ),
    );
  }
}

// ── Book shelf tab ──────────────────────────────────────────────────

class _BookShelf extends ConsumerWidget {
  final List<PersonalBook> books;
  final IconData emptyIcon;
  final String emptyMessage;
  final String emptySubtitle;

  const _BookShelf({
    required this.books,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              emptySubtitle,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final pb = books[index];
        return _PersonalBookTile(
          personalBook: pb,
          onMove: (shelf) {
            ref.read(personalLibraryNotifierProvider.notifier).moveToShelf(
                  personalBookId: pb.id,
                  shelf: shelf,
                );
          },
          onToggleOwned: () {
            ref.read(personalLibraryNotifierProvider.notifier).toggleOwned(
                  personalBookId: pb.id,
                  isOwned: !pb.isOwned,
                );
          },
          onRemove: () {
            ref
                .read(personalLibraryNotifierProvider.notifier)
                .removeBook(personalBookId: pb.id);
          },
        );
      },
    );
  }
}

// ── Reading tab (club reads + personal reads) ──────────────────────

class _ReadingTab extends ConsumerWidget {
  final List<PersonalBook> personalReading;
  final List<PersonalBook> allPersonalBooks;

  const _ReadingTab({
    required this.personalReading,
    required this.allPersonalBooks,
  });

  _BookMatch _matchClubBook(ClubCurrentBook clubBook) {
    final sourceId = clubBook.sourceBookId;
    if (sourceId == null) {
      return (personalBook: null, isOwned: false, isRead: false, isReading: false);
    }
    final matches = allPersonalBooks.where((pb) => pb.bookId == sourceId);
    if (matches.isEmpty) {
      return (personalBook: null, isOwned: false, isRead: false, isReading: false);
    }
    final pb = matches.first;
    return (
      personalBook: pb,
      isOwned: pb.isOwned,
      isRead: pb.shelf == Shelf.finished,
      isReading: pb.shelf == Shelf.reading,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubBooksAsync = ref.watch(clubCurrentBooksProvider);

    final clubBooks = clubBooksAsync.when(
      data: (books) => books,
      loading: () => <ClubCurrentBook>[],
      error: (_, __) => <ClubCurrentBook>[],
    );

    // Filter out personal books that are already shown as club reads.
    // Match by sourceBookId first, then fall back to title+author for
    // entries created before source_book_id was stored.
    final clubSourceIds = clubBooks
        .where((cb) => cb.sourceBookId != null)
        .map((cb) => cb.sourceBookId!)
        .toSet();
    final clubTitles = clubBooks
        .map((cb) => '${cb.book.title}|${cb.book.author}'.toLowerCase())
        .toSet();
    final filteredPersonal = personalReading.where((pb) {
      if (clubSourceIds.contains(pb.bookId)) return false;
      final pbKey = '${pb.title ?? ''}|${pb.author ?? ''}'.toLowerCase();
      if (clubTitles.contains(pbKey) && pbKey != '|') return false;
      return true;
    }).toList();

    if (clubBooks.isEmpty && filteredPersonal.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No books in progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add a book you\'re reading',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (clubBooks.isNotEmpty) ...[
          const _SectionHeader(title: 'Club Reads', count: 0, showCount: false),
          ...clubBooks.map((cb) {
            final match = _matchClubBook(cb);
            return _ClubBookTile(
              clubBook: cb,
              match: match,
              onAddToLibrary: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Add to My Library?'),
                    content: Text(
                      'Add "${cb.book.title}" to your library?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                // Use the original Google Books ID so the personal
                // book entry can be matched back to the club book.
                final bookWithSourceId = cb.sourceBookId != null
                    ? Book(
                        id: cb.sourceBookId!,
                        title: cb.book.title,
                        author: cb.book.author,
                        coverUrl: cb.book.coverUrl,
                        pageCount: cb.book.pageCount,
                        description: cb.book.description,
                        publisher: cb.book.publisher,
                        publishedDate: cb.book.publishedDate,
                        editionInfo: cb.book.editionInfo,
                        createdAt: cb.book.createdAt,
                      )
                    : cb.book;
                await ref
                    .read(personalLibraryNotifierProvider.notifier)
                    .addBook(
                      book: bookWithSourceId,
                      shelf: Shelf.reading,
                      isOwned: true,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Added "${cb.book.title}" to My Library',
                      ),
                    ),
                  );
                }
              },
            );
          }),
          if (filteredPersonal.isNotEmpty) const SizedBox(height: 16),
        ],
        if (filteredPersonal.isNotEmpty) ...[
          if (clubBooks.isNotEmpty)
            const _SectionHeader(title: 'Personal', count: 0, showCount: false),
          ...filteredPersonal.map((pb) => _PersonalBookTile(
                personalBook: pb,
                onMove: (shelf) {
                  ref
                      .read(personalLibraryNotifierProvider.notifier)
                      .moveToShelf(personalBookId: pb.id, shelf: shelf);
                },
                onToggleOwned: () {
                  ref.read(personalLibraryNotifierProvider.notifier).toggleOwned(
                        personalBookId: pb.id,
                        isOwned: !pb.isOwned,
                      );
                },
                onRemove: () {
                  ref
                      .read(personalLibraryNotifierProvider.notifier)
                      .removeBook(personalBookId: pb.id);
                },
              )),
        ],
      ],
    );
  }
}

// ── Club book tile ─────────────────────────────────────────────────

class _ClubBookTile extends StatelessWidget {
  final ClubCurrentBook clubBook;
  final _BookMatch match;
  final VoidCallback onAddToLibrary;

  const _ClubBookTile({
    required this.clubBook,
    required this.match,
    required this.onAddToLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final book = clubBook.book;
    final clubName = clubBook.club.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            SizedBox(
              width: 48,
              height: 72,
              child: book.coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: book.coverUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.menu_book, size: 24, color: Colors.grey[400]),
                    ),
            ),
            const SizedBox(width: 12),
            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  // Club name tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Reading with $clubName',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Status tags
                  Wrap(
                    spacing: 6,
                    children: [
                      if (match.isOwned)
                        _StatusChip(label: 'Owned', color: Colors.green),
                      if (match.isRead)
                        _StatusChip(label: 'Read', color: Colors.blue),
                      if (match.isReading)
                        _StatusChip(label: 'In your library', color: Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
            // Add to library action
            if (!match.isOwned && !match.isReading && !match.isRead)
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add to My Library',
                onPressed: onAddToLibrary,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── My Library shelf (owned books, split by read/unread) ────────────

class _LibraryShelf extends ConsumerWidget {
  final List<PersonalBook> books;

  const _LibraryShelf({required this.books});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shelves, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Your library is empty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mark books you own to see them here',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    final read = books.where((b) => b.shelf == Shelf.finished).toList();
    final unread = books.where((b) => b.shelf != Shelf.finished).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (unread.isNotEmpty) ...[
          _SectionHeader(
            title: 'Unread',
            count: unread.length,
          ),
          ...unread.map((pb) => _PersonalBookTile(
                personalBook: pb,
                onMove: (shelf) {
                  ref
                      .read(personalLibraryNotifierProvider.notifier)
                      .moveToShelf(personalBookId: pb.id, shelf: shelf);
                },
                onToggleOwned: () {
                  ref
                      .read(personalLibraryNotifierProvider.notifier)
                      .toggleOwned(personalBookId: pb.id, isOwned: false);
                },
                onRemove: () {
                  ref
                      .read(personalLibraryNotifierProvider.notifier)
                      .removeBook(personalBookId: pb.id);
                },
              )),
        ],
        if (read.isNotEmpty) ...[
          if (unread.isNotEmpty) const SizedBox(height: 16),
          _SectionHeader(
            title: 'Read',
            count: read.length,
          ),
          ...read.map((pb) => _PersonalBookTile(
                personalBook: pb,
                onMove: (shelf) {
                  ref
                      .read(personalLibraryNotifierProvider.notifier)
                      .moveToShelf(personalBookId: pb.id, shelf: shelf);
                },
                onToggleOwned: () {
                  ref
                      .read(personalLibraryNotifierProvider.notifier)
                      .toggleOwned(personalBookId: pb.id, isOwned: false);
                },
                onRemove: () {
                  ref
                      .read(personalLibraryNotifierProvider.notifier)
                      .removeBook(personalBookId: pb.id);
                },
              )),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool showCount;

  const _SectionHeader({
    required this.title,
    required this.count,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),
          if (showCount) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Book tile ───────────────────────────────────────────────────────

class _PersonalBookTile extends StatelessWidget {
  final PersonalBook personalBook;
  final ValueChanged<Shelf> onMove;
  final VoidCallback onToggleOwned;
  final VoidCallback onRemove;

  const _PersonalBookTile({
    required this.personalBook,
    required this.onMove,
    required this.onToggleOwned,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: SizedBox(
          width: 40,
          height: 60,
          child: personalBook.coverUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: personalBook.coverUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.menu_book, size: 20, color: Colors.grey[400]),
                ),
        ),
        title: Text(
          personalBook.title ?? personalBook.bookId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (personalBook.author != null)
              Text(
                personalBook.author!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            Text(
              '${personalBook.percentComplete.toStringAsFixed(0)}% complete',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'reading':
                onMove(Shelf.reading);
              case 'want_to_read':
                onMove(Shelf.wantToRead);
              case 'finished':
                onMove(Shelf.finished);
              case 'toggle_owned':
                onToggleOwned();
              case 'remove':
                onRemove();
            }
          },
          itemBuilder: (context) => [
            if (personalBook.shelf != Shelf.reading)
              const PopupMenuItem(
                  value: 'reading', child: Text('Move to Reading')),
            if (personalBook.shelf != Shelf.wantToRead)
              const PopupMenuItem(
                  value: 'want_to_read', child: Text('Add to Queue')),
            if (personalBook.shelf != Shelf.finished)
              const PopupMenuItem(
                  value: 'finished', child: Text('Mark as Finished')),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'toggle_owned',
              child: Text(personalBook.isOwned
                  ? 'Remove from My Library'
                  : 'Add to My Library'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'remove',
              child: Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add book search sheet ───────────────────────────────────────────

class _AddBookSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Future<void> Function(Book book, Shelf shelf, {bool isOwned})
      onBookSelected;

  const _AddBookSheet({
    required this.scrollController,
    required this.onBookSelected,
  });

  @override
  State<_AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends State<_AddBookSheet> {
  final _searchController = TextEditingController();
  final _service = GoogleBooksService();
  List<Book> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _loading = true);
    try {
      final results = await _service.search(query);
      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectBook(Book book) {
    showDialog(
      context: context,
      builder: (ctx) => _AddBookDialog(
        book: book,
        onConfirm: (shelf, isOwned) {
          Navigator.pop(ctx);
          widget.onBookSelected(book, shelf, isOwned: isOwned);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by title or author...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _search,
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )
        else
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Search for a book to add'
                          : 'No results found',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final book = _results[index];
                      return ListTile(
                        leading: SizedBox(
                          width: 40,
                          height: 60,
                          child: book.coverUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: CachedNetworkImage(
                                    imageUrl: book.coverUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.menu_book, size: 20),
                                ),
                        ),
                        title: Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: book.pageCount != null
                            ? Text('${book.pageCount} pp.',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12))
                            : null,
                        onTap: () => _selectBook(book),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}

// ── Add book dialog with ownership toggle ───────────────────────────

class _AddBookDialog extends StatefulWidget {
  final Book book;
  final void Function(Shelf shelf, bool isOwned) onConfirm;

  const _AddBookDialog({
    required this.book,
    required this.onConfirm,
  });

  @override
  State<_AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<_AddBookDialog> {
  bool _isOwned = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add this book to which shelf?'),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _isOwned,
                onChanged: (v) => setState(() => _isOwned = v ?? false),
              ),
              const Text('I own this book'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => widget.onConfirm(Shelf.reading, _isOwned),
          child: const Text('Reading'),
        ),
        TextButton(
          onPressed: () => widget.onConfirm(Shelf.wantToRead, _isOwned),
          child: const Text('Want to Read'),
        ),
        TextButton(
          onPressed: () => widget.onConfirm(Shelf.finished, _isOwned),
          child: const Text('Finished'),
        ),
      ],
    );
  }
}
