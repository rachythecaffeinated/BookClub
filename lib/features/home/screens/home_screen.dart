import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/club_activity_card.dart';
import '../widgets/currently_reading_card.dart';
import '../widgets/reading_goals_snapshot_card.dart';
import '../widgets/streak_heatmap_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          StreakHeatmapCard(),
          SizedBox(height: 16),
          CurrentlyReadingCard(),
          SizedBox(height: 16),
          ClubActivityCard(),
          SizedBox(height: 16),
          ReadingGoalsSnapshotCard(),
        ],
      ),
    );
  }
}
