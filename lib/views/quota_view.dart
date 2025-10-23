import 'package:flutter/material.dart';

class QuotaView extends StatelessWidget {
  const QuotaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quota'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nutritional Goals',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _QuotaCard(
              label: 'Carbohydrates',
              current: 0,
              target: 250,
              unit: 'g',
              color: Colors.orange,
              icon: Icons.grain,
            ),
            const SizedBox(height: 16),
            _QuotaCard(
              label: 'Fats',
              current: 0,
              target: 70,
              unit: 'g',
              color: Colors.yellow,
              icon: Icons.water_drop,
            ),
            const SizedBox(height: 16),
            _QuotaCard(
              label: 'Protein',
              current: 0,
              target: 50,
              unit: 'g',
              color: Colors.red,
              icon: Icons.fitness_center,
            ),
            const SizedBox(height: 16),
            _QuotaCard(
              label: 'Calories',
              current: 0,
              target: 2000,
              unit: 'kcal',
              color: Colors.deepOrange,
              icon: Icons.local_fire_department,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Open settings to adjust quotas
              },
              icon: const Icon(Icons.settings),
              label: const Text('Adjust Goals'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final String unit;
  final Color color;
  final IconData icon;

  const _QuotaCard({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (current / target).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}% of daily goal',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
