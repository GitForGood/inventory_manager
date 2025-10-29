import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';

/// Bottom sheet for setting inventory calorie target
/// Supports both manual entry and calculator mode
class CalorieTargetBottomSheet extends StatefulWidget {
  final int? currentTarget;

  const CalorieTargetBottomSheet({
    super.key,
    this.currentTarget,
  });

  @override
  State<CalorieTargetBottomSheet> createState() => _CalorieTargetBottomSheetState();
}

class _CalorieTargetBottomSheetState extends State<CalorieTargetBottomSheet> {
  bool _isCalculatorMode = false;

  // Manual mode
  late TextEditingController _manualController;

  // Calculator mode
  late TextEditingController _peopleController;
  late TextEditingController _daysController;
  late TextEditingController _percentageController;
  int _dailyCaloriesPerPerson = 2000; // Default daily calorie needs

  int? _calculatedTarget;

  @override
  void initState() {
    super.initState();
    _manualController = TextEditingController(
      text: widget.currentTarget?.toString() ?? '',
    );
    _peopleController = TextEditingController(text: '1');
    _daysController = TextEditingController(text: '30');
    _percentageController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _manualController.dispose();
    _peopleController.dispose();
    _daysController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  void _calculateTarget() {
    final people = int.tryParse(_peopleController.text) ?? 1;
    final days = int.tryParse(_daysController.text) ?? 30;
    final percentage = int.tryParse(_percentageController.text) ?? 100;

    setState(() {
      _calculatedTarget = (people * days * _dailyCaloriesPerPerson * percentage / 100).round();
    });
  }

  void _saveTarget(BuildContext context) {
    final int? target;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isCalculatorMode) {
      target = _calculatedTarget;
    } else {
      target = int.tryParse(_manualController.text);
    }

    if (target != null && target > 0) {
      context.read<SettingsBloc>().add(UpdateInventoryCalorieTarget(target));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calorie target set to ${_formatNumber(target)} kcal'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid calorie target'),
        ),
      );
    }
  }

  void _clearTarget(BuildContext context) {
    context.read<SettingsBloc>().add(const UpdateInventoryCalorieTarget(0));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calorie target cleared'),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Set Calorie Target',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Set a target for total calories in your inventory',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Mode selector
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Manual'),
                    icon: Icon(Icons.edit),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Calculator'),
                    icon: Icon(Icons.calculate),
                  ),
                ],
                selected: {_isCalculatorMode},
                onSelectionChanged: (Set<bool> selected) {
                  setState(() {
                    _isCalculatorMode = selected.first;
                    if (_isCalculatorMode) {
                      _calculateTarget();
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              // Content based on mode
              if (!_isCalculatorMode) ...[
                // Manual mode
                TextField(
                  controller: _manualController,
                  decoration: const InputDecoration(
                    labelText: 'Target Calories',
                    hintText: 'Enter total calories',
                    suffixText: 'kcal',
                    border: OutlineInputBorder(),
                    helperText: 'Total calorie storage goal for your inventory',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ] else ...[
                // Calculator mode
                Text(
                  'Calculate target based on:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Number of people
                TextField(
                  controller: _peopleController,
                  decoration: const InputDecoration(
                    labelText: 'Number of People',
                    hintText: 'How many people to feed',
                    suffixText: 'people',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _calculateTarget(),
                ),
                const SizedBox(height: 16),

                // Number of days
                TextField(
                  controller: _daysController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Days',
                    hintText: 'Storage duration',
                    suffixText: 'days',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _calculateTarget(),
                ),
                const SizedBox(height: 16),

                // Daily calories per person selector
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Daily calories per person:',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    DropdownButton<int>(
                      value: _dailyCaloriesPerPerson,
                      items: const [
                        DropdownMenuItem(value: 1500, child: Text('1,500 kcal')),
                        DropdownMenuItem(value: 2000, child: Text('2,000 kcal')),
                        DropdownMenuItem(value: 2500, child: Text('2,500 kcal')),
                        DropdownMenuItem(value: 3000, child: Text('3,000 kcal')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _dailyCaloriesPerPerson = value;
                            _calculateTarget();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Percentage of daily needs
                TextField(
                  controller: _percentageController,
                  decoration: const InputDecoration(
                    labelText: 'Percentage of Daily Needs',
                    hintText: 'What % of daily calories',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                    helperText: '100% = full daily calories, 50% = half',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _calculateTarget(),
                ),
                const SizedBox(height: 16),

                // Calculated result
                if (_calculatedTarget != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Calculated Target',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                              Text(
                                '${_formatNumber(_calculatedTarget!)} kcal',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  if (widget.currentTarget != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _clearTarget(context),
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ),
                  if (widget.currentTarget != null) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _saveTarget(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Set Target'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
