import 'package:flutter/material.dart';

class MyBooksScreen extends StatelessWidget {
  const MyBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Books'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reading'),
              Tab(text: 'Want to Read'),
              Tab(text: 'Finished'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EmptyShelf(
              icon: Icons.auto_stories,
              message: 'No books in progress',
              subtitle: 'Tap + to add a book you\'re reading',
            ),
            _EmptyShelf(
              icon: Icons.bookmark_border,
              message: 'Your TBR pile is empty',
              subtitle: 'Add books you want to read next',
            ),
            _EmptyShelf(
              icon: Icons.done_all,
              message: 'No finished books yet',
              subtitle: 'Completed books will appear here',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Navigate to add personal book (scan/search)
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _EmptyShelf extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyShelf({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
