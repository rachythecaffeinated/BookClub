import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/book.dart';

class GoogleBooksService {
  static const _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  /// Look up a book by ISBN.
  /// Falls back to Open Library API if Google Books returns no results.
  Future<Book?> lookupByIsbn(String isbn) async {
    final book = await _googleBooksLookup(isbn);
    if (book != null) return book;
    return _openLibraryFallback(isbn);
  }

  /// Search books by title and/or author.
  /// Tries Google Books first; falls back to Open Library if rate-limited.
  Future<List<Book>> search(String query) async {
    final apiKey = ApiConstants.googleBooksApiKey;
    final keyParam = apiKey.isNotEmpty ? '&key=$apiKey' : '';
    final uri = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(query)}'
        '&maxResults=20$keyParam');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        return items.map((item) => _parseGoogleBook(item)).toList();
      }
    }

    // Fallback to Open Library search.
    return _openLibrarySearch(query);
  }

  Future<List<Book>> _openLibrarySearch(String query) async {
    final uri = Uri.parse(
      'https://openlibrary.org/search.json'
      '?q=${Uri.encodeComponent(query)}&limit=20',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body) as Map<String, dynamic>;
    final docs = data['docs'] as List<dynamic>?;
    if (docs == null) return [];

    return docs.map((doc) {
      final d = doc as Map<String, dynamic>;
      final authors = d['author_name'] as List<dynamic>?;
      final coverId = d['cover_i'] as int?;
      String? coverUrl;
      if (coverId != null) {
        coverUrl = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
      }

      // Try to extract ISBN.
      String? isbn;
      final isbns = d['isbn'] as List<dynamic>?;
      if (isbns != null && isbns.isNotEmpty) {
        // Prefer ISBN-13 (length 13).
        isbn = isbns.firstWhere(
          (i) => (i as String).length == 13,
          orElse: () => isbns.first,
        ) as String;
      }

      return Book(
        id: '',
        isbn: isbn,
        title: d['title'] as String? ?? 'Unknown Title',
        author: authors?.join(', ') ?? 'Unknown Author',
        coverUrl: coverUrl,
        pageCount: d['number_of_pages_median'] as int?,
        publisher: (d['publisher'] as List<dynamic>?)?.isNotEmpty == true
            ? (d['publisher'] as List<dynamic>).first as String
            : null,
        publishedDate: d['first_publish_year']?.toString(),
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  Future<Book?> _googleBooksLookup(String isbn) async {
    final apiKey = ApiConstants.googleBooksApiKey;
    final keyParam = apiKey.isNotEmpty ? '&key=$apiKey' : '';
    final uri = Uri.parse('$_baseUrl?q=isbn:$isbn$keyParam');

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return null;

    return _parseGoogleBook(items.first);
  }

  Future<Book?> _openLibraryFallback(String isbn) async {
    final uri = Uri.parse(
      'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn'
      '&format=json&jscmd=data',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body) as Map<String, dynamic>;
    final key = 'ISBN:$isbn';
    if (!data.containsKey(key)) return null;

    final bookData = data[key] as Map<String, dynamic>;
    final authors = bookData['authors'] as List<dynamic>?;

    return Book(
      id: '', // Will be assigned by Firestore on insert
      isbn: isbn,
      title: bookData['title'] as String? ?? 'Unknown Title',
      author: authors?.isNotEmpty == true
          ? (authors!.first['name'] as String? ?? 'Unknown Author')
          : 'Unknown Author',
      coverUrl: bookData['cover'] != null
          ? (bookData['cover'] as Map<String, dynamic>)['large'] as String?
          : null,
      pageCount: bookData['number_of_pages'] as int?,
      publisher: (bookData['publishers'] as List<dynamic>?)?.isNotEmpty == true
          ? (bookData['publishers'] as List<dynamic>).first['name'] as String?
          : null,
      publishedDate: bookData['publish_date'] as String?,
      createdAt: DateTime.now(),
    );
  }

  Book _parseGoogleBook(dynamic item) {
    final info = item['volumeInfo'] as Map<String, dynamic>? ?? {};
    final identifiers =
        info['industryIdentifiers'] as List<dynamic>? ?? [];
    String? isbn;
    for (final id in identifiers) {
      final idMap = id as Map<String, dynamic>;
      if (idMap['type'] == 'ISBN_13') {
        isbn = idMap['identifier'] as String?;
        break;
      }
      if (idMap['type'] == 'ISBN_10') {
        isbn = idMap['identifier'] as String?;
      }
    }

    final imageLinks = info['imageLinks'] as Map<String, dynamic>?;

    return Book(
      id: '', // Will be assigned by Firestore on insert
      isbn: isbn,
      title: info['title'] as String? ?? 'Unknown Title',
      author: (info['authors'] as List<dynamic>?)?.join(', ') ??
          'Unknown Author',
      coverUrl: imageLinks?['thumbnail'] as String?,
      pageCount: info['pageCount'] as int?,
      description: info['description'] as String?,
      publisher: info['publisher'] as String?,
      publishedDate: info['publishedDate'] as String?,
      createdAt: DateTime.now(),
    );
  }
}
