import 'package:flutter_test/flutter_test.dart';

import 'package:book_club/core/models/models.dart';

void main() {
  group('Book model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'test-id',
        'isbn': '9780593135204',
        'title': 'Project Hail Mary',
        'author': 'Andy Weir',
        'cover_url': null,
        'page_count': 476,
        'description': 'A lone astronaut must save Earth.',
        'publisher': 'Ballantine Books',
        'published_date': '2021-05-04',
        'edition_info': null,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final book = Book.fromJson(json);

      expect(book.id, 'test-id');
      expect(book.isbn, '9780593135204');
      expect(book.title, 'Project Hail Mary');
      expect(book.author, 'Andy Weir');
      expect(book.pageCount, 476);
    });
  });

  group('ReadingProgress model', () {
    test('displayProgress formats page number', () {
      final progress = ReadingProgress(
        id: 'p1',
        userId: 'u1',
        clubId: 'c1',
        bookId: 'b1',
        currentPage: 187,
        percentComplete: 39.3,
        updatedAt: DateTime.now(),
      );

      expect(progress.displayProgress, 'pg. 187');
    });

    test('displayProgress formats audiobook timestamp', () {
      final progress = ReadingProgress(
        id: 'p2',
        userId: 'u1',
        clubId: 'c1',
        bookId: 'b1',
        currentTimestampSec: 16330, // 4:32:10
        percentComplete: 62.0,
        updatedAt: DateTime.now(),
      );

      expect(progress.displayProgress, '4:32:10');
    });

    test('isFinished returns true at 100%', () {
      final progress = ReadingProgress(
        id: 'p3',
        userId: 'u1',
        clubId: 'c1',
        bookId: 'b1',
        percentComplete: 100.0,
        updatedAt: DateTime.now(),
      );

      expect(progress.isFinished, true);
    });
  });

  group('ReadingStreak model', () {
    test('milestoneLabel returns correct labels', () {
      expect(
        const ReadingStreak(userId: 'u1', currentStreak: 7).milestoneLabel,
        'One week strong',
      );
      expect(
        const ReadingStreak(userId: 'u1', currentStreak: 30).milestoneLabel,
        'Monthly reader',
      );
      expect(
        const ReadingStreak(userId: 'u1', currentStreak: 100).milestoneLabel,
        'Century club',
      );
      expect(
        const ReadingStreak(userId: 'u1', currentStreak: 365).milestoneLabel,
        'Year-round reader',
      );
    });
  });
}
