import 'package:flutter/material.dart';

class ScanBookScreen extends StatelessWidget {
  final String clubId;

  const ScanBookScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Book')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Point at the barcode\non the back cover',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Camera will open here with mobile_scanner\nto detect ISBN-10 and ISBN-13 barcodes',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to manual search
                },
                child: const Text('Search by title instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
