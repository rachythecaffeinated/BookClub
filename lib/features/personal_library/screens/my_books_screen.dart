import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/models/book.dart';
import '../../../core/models/personal_book.dart';
import '../../../core/providers/personal_library_provider.dart';
import '../../../core/services/google_books_service.dart';
import '../../../shared/widgets/screen_header.dart';

typedef _BookMatch = ({
  PersonalBook? personalBook,
  bool isOwned,
  bool isRead,
  bool isReading
});

class MyBooksScreen extends ConsumerStatefulWidget {
  const MyBooksScreen({super.key});

  @override
  ConsumerState<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends ConsumerState<MyBooksScreen> {
  int _selectedTab = 0;
  final _tabLabels = ['Reading', 'Want to Read', 'My Library', 'Finished'];

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(personalBooksProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: booksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (books) {
            final totalCount = books.length;
            return Column(
              children: [
                ScreenHeader(
                  sectionLabel: '$totalCount BOOKS TOTAL',
                  titlePrefix: 'My ',
                  titleAccent: 'Books',
                ),
                // Pill tab selector (scrollable for 4 tabs)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _PillTabBar(
                    labels: _tabLabels,
                    selectedIndex: _selectedTab,
                    onTap: (i) => setState(() => _selectedTab = i),
                  ),
                ),
                const SizedBox(height: 12),
                // Tab content
                Expanded(
                  child: _buildTabContent(books),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBookSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabContent(List<PersonalBook> books) {
    switch (_selectedTab) {
      case 0:
        final reading =
            books.where((b) => b.shelf == Shelf.reading).toList();
        return _ReadingTab(
          personalReading: reading,
          allPersonalBooks: books,
        );
      case 1:
        final wantToRead =
            books.where((b) => b.shelf == Shelf.wantToRead).toList();
        return _BookGrid(
          books: wantToRead,
          emptyIcon: Icons.bookmark_border,
          emptyMessage: 'Your TBR pile is empty',
          emptySubtitle: 'Add books you want to read next',
        );
      case 2:
        final owned = books.where((b) => b.isOwned).toList();
        return _LibraryTab(books: owned);
      case 3:
        final finished =
            books.where((b) => b.shelf == Shelf.finished).toList();
        return _BookGrid(
          books: finished,
          emptyIcon: Icons.done_all,
          emptyMessage: 'No finished books yet',
          emptySubtitle: 'Completed books will appear here',
        );
      default:
        return const SizedBox.shrink();
    }
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
                SnackBar(
                    content: Text('Added "${book.title}" to your shelf')),
              );
            }
          },
        ),
      ),
    );
  }
}

// ── Pill Tab Bar ─────────────────────────────────────────────────────

class _PillTabBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _PillTabBar({
    required this.labels,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(labels.length, (i) {
            final selected = i == selectedIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.darkCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: selected
                        ? AppTheme.textOnDark
                        : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Reading tab (club reads + personal reads) ────────────────────────

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
      return (
        personalBook: null,
        isOwned: false,
        isRead: false,
        isReading: false
      );
    }
    final matches = allPersonalBooks.where((pb) => pb.bookId == sourceId);
    if (matches.isEmpty) {
      return (
        personalBook: null,
        isOwned: false,
        isRead: false,
        isReading: false
      );
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

    // Filter out personal books already shown as club reads.
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
            Icon(Icons.auto_stories, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No books in progress',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add a book you\'re reading',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (clubBooks.isNotEmpty) ...[
          const _SectionLabel(title: 'Club Reads'),
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
                    content: Text('Add "${cb.book.title}" to your library?'),
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
                      content: Text('Added "${cb.book.title}" to My Library'),
                    ),
                  );
                }
              },
            );
          }),
          if (filteredPersonal.isNotEmpty) const SizedBox(height: 12),
        ],
        if (filteredPersonal.isNotEmpty) ...[
          if (clubBooks.isNotEmpty) const _SectionLabel(title: 'Personal'),
          ...filteredPersonal.map((pb) => _PersonalBookTile(
                personalBook: pb,
                onMove: (shelf) {
                  ref
                      .read(personalLibraryNotifierProvider.notifier)
                      .moveToShelf(personalBookId: pb.id, shelf: shelf);
                },
                onToggleOwned: () {
                  ref
                      .read(personalLibraryNotifierProvider.notifier)
                      .toggleOwned(
                          personalBookId: pb.id, isOwned: !pb.isOwned);
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

// ── Book grid (for Want to Read + Finished) ─────────────────────────

class _BookGrid extends ConsumerWidget {
  final List<PersonalBook> books;
  final IconData emptyIcon;
  final String emptyMessage;
  final String emptySubtitle;

  const _BookGrid({
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
            Icon(emptyIcon, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              emptySubtitle,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) =>
          _BookGridCard(personalBook: books[index], ref: ref),
    );
  }
}

// ── My Library tab (owned, split by read/unread) ────────────────────

class _LibraryTab extends ConsumerWidget {
  final List<PersonalBook> books;

  const _LibraryTab({required this.books});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shelves, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Your library is empty',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Mark books you own to see them here',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    final read = books.where((b) => b.shelf == Shelf.finished).toList();
    final unread = books.where((b) => b.shelf != Shelf.finished).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (unread.isNotEmpty) ...[
          _SectionLabel(title: 'Unread', count: unread.length),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.55,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: unread.length,
            itemBuilder: (context, index) =>
                _BookGridCard(personalBook: unread[index], ref: ref),
          ),
        ],
        if (read.isNotEmpty) ...[
          if (unread.isNotEmpty) const SizedBox(height: 16),
          _SectionLabel(title: 'Read', count: read.length),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.55,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: read.length,
            itemBuilder: (context, index) =>
                _BookGridCard(personalBook: read[index], ref: ref),
          ),
        ],
      ],
    );
  }
}

// ── Section Label ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final int? count;

  const _SectionLabel({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppTheme.textSecondary,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Club book tile ──────────────────────────────────────────────────

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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          SizedBox(
            width: 48,
            height: 72,
            child: book.coverUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_book,
                        size: 24, color: AppTheme.textSecondary),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                // Club name tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Reading with $clubName',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (clubBook.myProgress != null &&
                    clubBook.myProgress!.percentComplete > 0) ...[
                  const SizedBox(height: 6),
                  _ProgressBar(
                    percent: clubBook.myProgress!.percentComplete,
                    currentPage: clubBook.myProgress!.currentPage,
                  ),
                ],
                // Status tags
                if (match.isOwned || match.isRead || match.isReading) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (match.isOwned)
                        _StatusChip(label: 'Owned', color: AppTheme.success),
                      if (match.isRead)
                        _StatusChip(label: 'Read', color: AppTheme.primary),
                      if (match.isReading)
                        _StatusChip(
                            label: 'In your library',
                            color: AppTheme.warning),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!match.isOwned && !match.isReading && !match.isRead)
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: AppTheme.primary),
              tooltip: 'Add to My Library',
              onPressed: onAddToLibrary,
            ),
        ],
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
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Progress bar ────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double percent;
  final int? currentPage;

  const _ProgressBar({required this.percent, this.currentPage});

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0.0, 100.0);
    final label = StringBuffer('${pct.toStringAsFixed(0)}%');
    if (currentPage != null && currentPage! > 0) {
      label.write(' · pg. $currentPage');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 5,
            backgroundColor: AppTheme.divider,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toString(),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

// ── Personal book tile ──────────────────────────────────────────────

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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Cover
            SizedBox(
              width: 44,
              height: 66,
              child: personalBook.coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: personalBook.coverUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.menu_book,
                          size: 20, color: AppTheme.textSecondary),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    personalBook.title ?? personalBook.bookId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (personalBook.author != null)
                    Text(
                      personalBook.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  if (personalBook.shelf == Shelf.reading) ...[
                    const SizedBox(height: 4),
                    _ProgressBar(
                      percent: personalBook.percentComplete,
                      currentPage: personalBook.currentPage,
                    ),
                  ] else
                    Text(
                      '${personalBook.percentComplete.toStringAsFixed(0)}% complete',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: AppTheme.textSecondary, size: 20),
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
                      value: 'finished',
                      child: Text('Mark as Finished')),
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
                  child:
                      Text('Remove', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Book Grid Card (for grid views) ─────────────────────────────────

class _BookGridCard extends StatelessWidget {
  final PersonalBook personalBook;
  final WidgetRef ref;

  const _BookGridCard({required this.personalBook, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: personalBook.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: personalBook.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppTheme.divider,
                          child: const Center(
                              child: Icon(Icons.auto_stories,
                                  size: 32,
                                  color: AppTheme.textSecondary)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.divider,
                          child: const Center(
                              child: Icon(Icons.auto_stories,
                                  size: 32,
                                  color: AppTheme.textSecondary)),
                        ),
                      )
                    : Container(
                        color: AppTheme.divider,
                        child: const Center(
                            child: Icon(Icons.auto_stories,
                                size: 32,
                                color: AppTheme.textSecondary)),
                      ),
              ),
            ),
            SizedBox(
              height: 6,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
                child: LinearProgressIndicator(
                  value: (personalBook.percentComplete / 100.0)
                      .clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppTheme.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                personalBook.title ?? 'Untitled',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            if (personalBook.shelf != Shelf.reading)
              ListTile(
                leading: const Icon(Icons.book_outlined),
                title: const Text('Move to Reading'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(personalLibraryNotifierProvider.notifier)
                      .moveToShelf(
                          personalBookId: personalBook.id,
                          shelf: Shelf.reading);
                },
              ),
            if (personalBook.shelf != Shelf.wantToRead)
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Add to Wishlist'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(personalLibraryNotifierProvider.notifier)
                      .moveToShelf(
                          personalBookId: personalBook.id,
                          shelf: Shelf.wantToRead);
                },
              ),
            if (personalBook.shelf != Shelf.finished)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Mark as Finished'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(personalLibraryNotifierProvider.notifier)
                      .moveToShelf(
                          personalBookId: personalBook.id,
                          shelf: Shelf.finished);
                },
              ),
            ListTile(
              leading:
                  Icon(Icons.delete_outline, color: Colors.red[400]),
              title: Text('Remove',
                  style: TextStyle(color: Colors.red[400])),
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(personalLibraryNotifierProvider.notifier)
                    .removeBook(personalBookId: personalBook.id);
              },
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
                                  child: const Icon(Icons.menu_book,
                                      size: 20),
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
      title: Text(widget.book.title,
          maxLines: 2, overflow: TextOverflow.ellipsis),
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
