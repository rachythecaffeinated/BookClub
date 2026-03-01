import 'package:flutter/material.dart';

class SearchBookScreen extends StatefulWidget {
  final String clubId;

  const SearchBookScreen({super.key, required this.clubId});

  @override
  State<SearchBookScreen> createState() => _SearchBookScreenState();
}

class _SearchBookScreenState extends State<SearchBookScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Books')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or author...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
              ),
              onSubmitted: (query) {
                // TODO: Call GoogleBooksService.search(query)
              },
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Search results will appear here',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
