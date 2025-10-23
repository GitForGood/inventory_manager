import 'package:flutter/material.dart';

class CalculatorView extends StatefulWidget {
  const CalculatorView({super.key});

  @override
  State<CalculatorView> createState() => _CalculatorViewState();
}

class _CalculatorViewState extends State<CalculatorView> {
  final TextEditingController _weightController = TextEditingController();
  Map<String, double>? _calculatedNutrition;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Calculate Nutrition',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (grams)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _calculateNutrition,
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate'),
            ),
            const SizedBox(height: 24),
            if (_calculatedNutrition != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              _NutritionCard(
                label: 'Carbohydrates',
                value: _calculatedNutrition!['carbohydrates']!,
                unit: 'g',
                icon: Icons.grain,
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              _NutritionCard(
                label: 'Fats',
                value: _calculatedNutrition!['fats']!,
                unit: 'g',
                icon: Icons.water_drop,
                color: Colors.yellow,
              ),
              const SizedBox(height: 8),
              _NutritionCard(
                label: 'Protein',
                value: _calculatedNutrition!['protein']!,
                unit: 'g',
                icon: Icons.fitness_center,
                color: Colors.red,
              ),
              const SizedBox(height: 8),
              _NutritionCard(
                label: 'Calories',
                value: _calculatedNutrition!['kcal']!,
                unit: 'kcal',
                icon: Icons.local_fire_department,
                color: Colors.deepOrange,
              ),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Enter weight and select a food item to calculate nutrition',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _calculateNutrition() {
    // TODO: Select food item and calculate
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Food item selection coming soon!'),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;

  const _NutritionCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} $unit',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
