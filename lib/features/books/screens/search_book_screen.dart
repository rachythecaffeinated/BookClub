import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/book.dart';
import '../../../core/providers/club_provider.dart';
import '../../../core/services/google_books_service.dart';

class SearchBookScreen extends ConsumerStatefulWidget {
  final String clubId;

  const SearchBookScreen({super.key, required this.clubId});

  @override
  ConsumerState<SearchBookScreen> createState() => _SearchBookScreenState();
}

class _SearchBookScreenState extends ConsumerState<SearchBookScreen> {
  final _searchController = TextEditingController();
  final _isbnController = TextEditingController();
  final _booksService = GoogleBooksService();
  List<Book>? _results;
  bool _loading = false;
  String? _error;
  bool _isbnMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    _isbnController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await _booksService.search(query.trim());
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _lookupIsbn(String isbn) async {
    final cleaned = isbn.trim().replaceAll('-', '').replaceAll(' ', '');
    if (cleaned.isEmpty) return;

    if (cleaned.length != 10 && cleaned.length != 13) {
      setState(() => _error = 'ISBN must be 10 or 13 digits');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _results = null;
    });

    try {
      final book = await _booksService.lookupByIsbn(cleaned);
      if (mounted) {
        if (book != null) {
          setState(() {
            _results = [book];
            _loading = false;
          });
        } else {
          setState(() {
            _error = 'No book found for ISBN $cleaned';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectBook(Book book) async {
    final result = await showDialog<Book>(
      context: context,
      builder: (context) => _ConfirmBookDialog(book: book),
    );

    if (result == null || !mounted) return;

    setState(() => _loading = true);

    try {
      await ref
          .read(clubNotifierProvider.notifier)
          .setCurrentBook(clubId: widget.clubId, book: result);

      if (mounted) {
        ref.invalidate(clubProvider(widget.clubId));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Books')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Title / Author'),
                  icon: Icon(Icons.search),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('ISBN'),
                  icon: Icon(Icons.numbers),
                ),
              ],
              selected: {_isbnMode},
              onSelectionChanged: (selected) {
                setState(() {
                  _isbnMode = selected.first;
                  _results = null;
                  _error = null;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isbnMode
                ? TextField(
                    controller: _isbnController,
                    decoration: InputDecoration(
                      hintText: 'Enter ISBN (10 or 13 digits)',
                      prefixIcon: const Icon(Icons.numbers),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _isbnController.clear();
                          setState(() {
                            _results = null;
                            _error = null;
                          });
                        },
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _lookupIsbn,
                  )
                : TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by title or author...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = null;
                            _error = null;
                          });
                        },
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                  ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_results == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Search by title or author',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_results!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No books found',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results!.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final book = _results![index];
        return _BookResultTile(book: book, onTap: () => _selectBook(book));
      },
    );
  }
}

class _BookResultTile extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookResultTile({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Build detail chips from available metadata.
    final details = <String>[];
    if (book.publishedDate != null && book.publishedDate!.isNotEmpty) {
      details.add(book.publishedDate!);
    }
    if (book.pageCount != null) {
      details.add('${book.pageCount} pages');
    }
    if (book.publisher != null && book.publisher!.isNotEmpty) {
      details.add(book.publisher!);
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            SizedBox(
              width: 48,
              height: 72,
              child: book.coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        book.coverUrl!,
                        width: 48,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderCover(),
                      ),
                    )
                  : _PlaceholderCover(),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      details.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.menu_book, size: 20, color: Colors.grey[400]),
    );
  }
}

class _ConfirmBookDialog extends StatefulWidget {
  final Book book;

  const _ConfirmBookDialog({required this.book});

  @override
  State<_ConfirmBookDialog> createState() => _ConfirmBookDialogState();
}

class _ConfirmBookDialogState extends State<_ConfirmBookDialog> {
  final _pageCountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.book.pageCount != null) {
      _pageCountController.text = widget.book.pageCount.toString();
    }
  }

  @override
  void dispose() {
    _pageCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set as Current Book?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${widget.book.title}" by ${widget.book.author}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pageCountController,
            decoration: InputDecoration(
              labelText: 'Total pages in your edition',
              hintText: 'e.g., 384',
              helperText: widget.book.pageCount != null
                  ? 'Pre-filled from search — update if your edition differs'
                  : 'Enter the page count for progress tracking',
              helperMaxLines: 2,
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final pages = int.tryParse(_pageCountController.text.trim());
            final updatedBook = Book(
              id: widget.book.id,
              isbn: widget.book.isbn,
              title: widget.book.title,
              author: widget.book.author,
              coverUrl: widget.book.coverUrl,
              pageCount: pages ?? widget.book.pageCount,
              description: widget.book.description,
              publisher: widget.book.publisher,
              publishedDate: widget.book.publishedDate,
              editionInfo: widget.book.editionInfo,
              createdAt: widget.book.createdAt,
            );
            Navigator.pop(context, updatedBook);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
