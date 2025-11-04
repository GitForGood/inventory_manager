import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';
import 'package:inventory_manager/models/daily_calorie_target.dart';

/// Bottom sheet for setting inventory calorie target
/// Supports both manual entry and calculator mode
class CalorieTargetBottomSheet extends StatefulWidget {
  final DailyCalorieTarget? currentTarget;

  const CalorieTargetBottomSheet({
    super.key,
    this.currentTarget,
  });

  @override
  State<CalorieTargetBottomSheet> createState() => _CalorieTargetBottomSheetState();
}

class _CalorieTargetBottomSheetState extends State<CalorieTargetBottomSheet> {
  late bool _isCalculatorMode;

  // Calculator mode
  late TextEditingController _peopleController;
  late TextEditingController _daysController;
  late TextEditingController _dailyCalorieController;

  final int _defaultPeopleAmount = 4;
  final int _defaultDaysAmount = 14;
  final int _defaultDailyCalories = 2000;

  int? _calculatedTarget;

  // Manual mode
  late TextEditingController _manualController;

  final int _defaultManualCalories = 112000; //4 * 14 * 2000

  @override
  void initState() {
    super.initState();

    // Determine mode based on whether dailyConsumption is set
    // If dailyConsumption exists, last mode was calculator
    // If target exists but no dailyConsumption, last mode was manual
    // If neither exists, default to calculator
    _isCalculatorMode = widget.currentTarget == null || widget.currentTarget is CalculatedCalorieTarget;
    
    final CalculatedCalorieTarget startingCalculatedTarget;
    if (widget.currentTarget is CalculatedCalorieTarget) {
      startingCalculatedTarget = widget.currentTarget as CalculatedCalorieTarget;
    } else {
      startingCalculatedTarget = CalculatedCalorieTarget(
        people: _defaultPeopleAmount, 
        days: _defaultDaysAmount, 
        caloriesPerPerson: _defaultDailyCalories
      );
    }

    _manualController = TextEditingController(
      text: widget.currentTarget?.target.toString() ?? '',
    );
    _peopleController = TextEditingController(text: startingCalculatedTarget.people.toString());
    _daysController = TextEditingController(text: startingCalculatedTarget.days.toString());
    _dailyCalorieController = TextEditingController(text: startingCalculatedTarget.caloriesPerPerson.toString());

    // Calculate the initial target if in calculator mode
    if (_isCalculatorMode) {
      _calculateTarget();
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    _peopleController.dispose();
    _daysController.dispose();
    _dailyCalorieController.dispose();
    super.dispose();
  }

  void _calculateTarget() {
    final people = int.tryParse(_peopleController.text) ?? _defaultPeopleAmount;
    final days = int.tryParse(_daysController.text) ?? _defaultDaysAmount;
    final dailyCalories = int.tryParse(_dailyCalorieController.text) ?? _defaultDailyCalories;

    setState(() {
      _calculatedTarget = (people * days * dailyCalories).round();
    });
  }

  void _saveTarget(BuildContext context) {
    final int target;
    if (_isCalculatorMode) {
      final calculatedTarget = CalculatedCalorieTarget(
        people: int.tryParse(_peopleController.text) ?? _defaultPeopleAmount, 
        days: int.tryParse(_daysController.text) ?? _defaultDaysAmount, 
        caloriesPerPerson: int.tryParse(_dailyCalorieController.text) ?? _defaultDailyCalories
      );
      target = calculatedTarget.target;
      context.read<SettingsBloc>().add(SetCalculateedDailyCalorieTarget(calculatedTarget));
    } else {
      target = int.tryParse(_manualController.text) ?? _defaultManualCalories;
      context.read<SettingsBloc>().add(SetManualCalorieTarget(ManualCalorieTarget(target: target)));
    }

    if (target > 0) {
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
    context.read<SettingsBloc>().add(const ClearDailyCalorieTarget());
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
                    value: true,
                    label: Text('Calculator'),
                    icon: Icon(Icons.calculate),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Manual'),
                    icon: Icon(Icons.edit),
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

                TextField(
                  controller: _dailyCalorieController,
                  decoration: const InputDecoration(
                    labelText: 'Daily Kcal per person',
                    hintText: 'individual caloric need per person per day',
                    suffixText: 'Kcal',
                    border: OutlineInputBorder(),
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
