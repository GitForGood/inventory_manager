import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';
import 'package:inventory_manager/models/daily_calorie_target.dart';
import 'package:inventory_manager/services/storage_calculator_service.dart';
import 'package:inventory_manager/widgets/assist_chip.dart';
import 'package:inventory_manager/widgets/calorie_target_bottom_sheet.dart';
import 'package:inventory_manager/widgets/outlined_card.dart';
import 'package:material_symbols_icons/symbols.dart';

class StorageSummaryCard extends StatelessWidget {
  final StorageStatus status;

  const StorageSummaryCard({super.key, required this.status});

  void _showCalorieTargetSheet(
    BuildContext context,
    DailyCalorieTarget? currentTarget,
    int? currentDailyConsumption,
  ) {
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
            ? settingsState.settings.dailyCalorieTarget
            : null;
        final dailyConsumption = settingsState is SettingsLoaded
            ? (settingsState.settings.dailyCalorieTarget is CalculatedCalorieTarget) ? (settingsState.settings.dailyCalorieTarget as CalculatedCalorieTarget).dailyConsumption : null
            : null;

        return OutlinedCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Storage Summary',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Horizontally scrollable chip row
                Wrap(
                  spacing: 8,
                  children: [
                    AssistChip(icon: Icons.inventory, labelText: '${status.totalItems.toString()} Items'),
                    AssistChip(icon: Symbols.package_2, labelText: '${status.totalBatches.toString()} Batches'),
                    // Only show Days chip if daily consumption is configured
                    if (status.estimatedDays != null) ...[
                      AssistChip(icon: Icons.calendar_today, labelText: '${status.estimatedDays!.toStringAsFixed(1)} Days'),
                    ],
                  ],
                ),
                // Calorie target progress
                const Divider(),
                //const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showCalorieTargetSheet(context, calorieTarget, dailyConsumption),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: calorieTarget != null
                        ? _buildCalorieProgress(
                            context,
                            theme,
                            calorieTarget.target,
                            status.totalCalories.toInt(),
                          )
                        : _buildSetCalorieTarget(context, theme),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetCalorieTarget(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.local_fire_department_outlined,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Tap to set calorie target',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
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
              color: Theme.of(context).colorScheme.secondary,
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
                color: isComplete ? theme.colorScheme.tertiary : Theme.of(context).colorScheme.secondary,
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
              isComplete ? theme.colorScheme.tertiary : Theme.of(context).colorScheme.secondary,
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