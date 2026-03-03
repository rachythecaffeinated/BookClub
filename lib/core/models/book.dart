import 'package:equatable/equatable.dart';

class Book extends Equatable {
  final String id;
  final String? isbn;
  final String title;
  final String author;
  final String? coverUrl;
  final int? pageCount;
  final String? description;
  final String? publisher;
  final String? publishedDate;
  final String? editionInfo;
  final DateTime createdAt;

  const Book({
    required this.id,
    this.isbn,
    required this.title,
    required this.author,
    this.coverUrl,
    this.pageCount,
    this.description,
    this.publisher,
    this.publishedDate,
    this.editionInfo,
    required this.createdAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      isbn: json['isbn'] as String?,
      title: json['title'] as String,
      author: json['author'] as String,
      coverUrl: json['cover_url'] as String?,
      pageCount: json['page_count'] as int?,
      description: json['description'] as String?,
      publisher: json['publisher'] as String?,
      publishedDate: json['published_date'] as String?,
      editionInfo: json['edition_info'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isbn': isbn,
      'title': title,
      'author': author,
      'cover_url': coverUrl,
      'page_count': pageCount,
      'description': description,
      'publisher': publisher,
      'published_date': publishedDate,
      'edition_info': editionInfo,
    };
  }

  @override
  List<Object?> get props => [
        id,
        isbn,
        title,
        author,
        coverUrl,
        pageCount,
      ];
}
