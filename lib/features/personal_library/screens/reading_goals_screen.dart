import 'package:flutter/material.dart';

class ReadingGoalsScreen extends StatefulWidget {
  const ReadingGoalsScreen({super.key});

  @override
  State<ReadingGoalsScreen> createState() => _ReadingGoalsScreenState();
}

class _ReadingGoalsScreenState extends State<ReadingGoalsScreen> {
  bool _weeklyEnabled = false;
  bool _monthlyEnabled = false;
  bool _yearlyEnabled = false;
  final _weeklyController = TextEditingController();
  final _monthlyController = TextEditingController();
  final _yearlyController = TextEditingController();

  @override
  void dispose() {
    _weeklyController.dispose();
    _monthlyController.dispose();
    _yearlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Goals')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Weekly goal
          _GoalCard(
            title: 'Weekly Goal',
            subtitle: 'Pages per week',
            icon: Icons.calendar_view_week,
            enabled: _weeklyEnabled,
            controller: _weeklyController,
            unitLabel: 'pages/week',
            onToggle: (v) => setState(() => _weeklyEnabled = v),
          ),
          const SizedBox(height: 16),

          // Monthly goal
          _GoalCard(
            title: 'Monthly Goal',
            subtitle: 'Pages or books per month',
            icon: Icons.calendar_month,
            enabled: _monthlyEnabled,
            controller: _monthlyController,
            unitLabel: 'pages/month',
            onToggle: (v) => setState(() => _monthlyEnabled = v),
          ),
          const SizedBox(height: 16),

          // Yearly goal
          _GoalCard(
            title: 'Yearly Goal',
            subtitle: 'Books this year',
            icon: Icons.calendar_today,
            enabled: _yearlyEnabled,
            controller: _yearlyController,
            unitLabel: 'books/year',
            onToggle: (v) => setState(() => _yearlyEnabled = v),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              // TODO: Save goals to Firestore
            },
            child: const Text('Save Goals'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final TextEditingController controller;
  final String unitLabel;
  final ValueChanged<bool> onToggle;

  const _GoalCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.controller,
    required this.unitLabel,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  suffixText: unitLabel,
                  hintText: 'Enter target...',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
