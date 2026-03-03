import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class CreateNoteScreen extends StatefulWidget {
  final String clubId;

  const CreateNoteScreen({super.key, required this.clubId});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _pageController = TextEditingController();
  final _noteController = TextEditingController();
  final _quoteController = TextEditingController();
  String _visibility = 'club';

  @override
  void dispose() {
    _pageController.dispose();
    _noteController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave a Note'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Save margin note to Firestore
            },
            child: const Text('Post'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _pageController,
            decoration: const InputDecoration(
              labelText: 'Page Number',
              prefixIcon: Icon(Icons.bookmark_outline),
              hintText: 'e.g., 187',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quoteController,
            decoration: InputDecoration(
              labelText: 'Quote (encouraged)',
              hintText: 'The passage you\'re reacting to...',
              prefixIcon: const Icon(Icons.format_quote),
              helperText:
                  'Adding a quote helps clubmates on other formats find this passage',
              helperMaxLines: 2,
              counterText:
                  '${_quoteController.text.length}/${AppConstants.quoteMaxLength}',
            ),
            maxLines: 3,
            maxLength: AppConstants.quoteMaxLength,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Your note',
              hintText: 'What are you thinking about this passage?',
              prefixIcon: const Icon(Icons.edit_note),
              counterText:
                  '${_noteController.text.length}/${AppConstants.marginNoteMaxLength}',
            ),
            maxLines: 5,
            maxLength: AppConstants.marginNoteMaxLength,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text(
            'Visibility',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'club',
                label: Text('Club'),
                icon: Icon(Icons.groups),
              ),
              ButtonSegment(
                value: 'private',
                label: Text('Private'),
                icon: Icon(Icons.lock),
              ),
            ],
            selected: {_visibility},
            onSelectionChanged: (selection) =>
                setState(() => _visibility = selection.first),
          ),
        ],
      ),
    );
  }
}
