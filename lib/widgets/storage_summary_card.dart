import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';
import 'package:inventory_manager/services/storage_calculator_service.dart';
import 'package:inventory_manager/views/calorie_target_bottom_sheet.dart';
import 'package:material_symbols_icons/symbols.dart';

class StorageSummaryCard extends StatelessWidget {
  final StorageStatus status;

  const StorageSummaryCard({super.key, required this.status});

  void _showCalorieTargetSheet(BuildContext context, int? currentTarget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CalorieTargetBottomSheet(
        currentTarget: currentTarget,
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

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final calorieTarget = settingsState is SettingsLoaded
            ? settingsState.settings.inventoryCalorieTarget
            : null;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Storage Overview',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Calorie target button
                    IconButton(
                      icon: Icon(
                        calorieTarget != null
                            ? Icons.local_fire_department
                            : Icons.local_fire_department_outlined,
                        color: calorieTarget != null
                            ? Colors.orange
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: calorieTarget != null
                          ? 'Edit calorie target'
                          : 'Set calorie target',
                      onPressed: () => _showCalorieTargetSheet(context, calorieTarget),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SummaryItem(
                      icon: Icons.inventory,
                      label: 'Items',
                      value: status.totalItems.toString(),
                      color: Theme.of(context).colorScheme.primary
                    ),
                    SummaryItem(
                      icon: Symbols.package_2,
                      label: 'Batches',
                      value: status.totalBatches.toString(),
                      color: Theme.of(context).colorScheme.primary
                    ),
                    SummaryItem(
                      icon: Icons.calendar_today,
                      label: 'Days',
                      value: status.estimatedDays.toStringAsFixed(1),
                      color: Theme.of(context).colorScheme.primary
                    ),
                  ],
                ),

                // Calorie target progress
                if (calorieTarget != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildCalorieProgress(
                    context,
                    theme,
                    calorieTarget,
                    (status.totalNutrition['kcal'] ?? 0).toInt(),
                  ),
                ],

                const SizedBox(height: 8),
                /*
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Limited by ${status.limitingFactor} (~${status.estimatedDays.toStringAsFixed(1)} days)',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                */
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalorieProgress(
    BuildContext context,
    ThemeData theme,
    int target,
    int current,
  ) {
    final progress = (current / target).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();
    final isComplete = current >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 20,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Calorie Storage Target',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '$percentage%',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isComplete ? Colors.green : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? Colors.green : theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_formatNumber(current)} kcal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Target: ${_formatNumber(target)} kcal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const SummaryItem({super.key, 
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}