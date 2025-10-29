import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventory_manager/bloc/consumption_quota/consumption_quota_barrel.dart';
import 'package:inventory_manager/models/consumption_quota.dart';

class FoodItemQuotaCard extends StatelessWidget {
  final String foodItemName;
  final List<ConsumptionQuota> quotas;

  const FoodItemQuotaCard({
    super.key,
    required this.foodItemName,
    required this.quotas,
  });

  @override
  Widget build(BuildContext context) {
    // With the new system, there should only be one quota per food item
    final quota = quotas.isNotEmpty ? quotas.first : null;

    if (quota == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isCollapsed = quota.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Food Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCollapsed
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.track_changes,
                    color: isCollapsed
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Title and Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        foodItemName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCollapsed
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Due: ${dateFormat.format(quota.targetDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Buttons / Indicators
                if (quota.isCompleted) ...[
                  // Completed indicator
                  Icon(
                    Icons.check_circle,
                    size: 32,
                    color: const Color(0xFF66BB6A),
                  ),
                ] else ...[
                  // Active quota button
                  // Increment button
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: colorScheme.primary,
                    iconSize: 32,
                    tooltip: 'Mark items as consumed',
                    onPressed: () {
                      _showIncrementDialog(context, quota);
                    },
                  ),
                ],
              ],
            ),

            // Progress Section (only shown when not collapsed)
            if (!isCollapsed) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${quota.consumedCount}/${quota.targetCount} items',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getProgressColor(quota.progressPercentage, context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: quota.progressPercentage / 100,
                            minHeight: 8,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(quota.progressPercentage, context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  /// Get progress bar color based on completion percentage
  /// Returns green when complete (100%), orange when near complete (>=80%),
  /// or blue for lower progress
  Color _getProgressColor(double percentage, BuildContext context) {
    if (percentage >= 100) {
      return Colors.green;
    } else if (percentage >= 80) {
      return Theme.of(context).colorScheme.primary;
    } else {
      return Theme.of(context).colorScheme.secondary;
    }
  }

  void _showIncrementDialog(BuildContext context, ConsumptionQuota quota) {
    double sliderValue = 1.0;
    final remainingCount = quota.remainingCount;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          void updateValue(double newValue) {
            setState(() {
              sliderValue = newValue;
            });
          }

          void showManualInputDialog() {
            final manualController = TextEditingController(
              text: sliderValue.round().toString(),
            );

            showDialog(
              context: context,
              builder: (inputContext) => AlertDialog(
                title: const Text('Enter Amount'),
                content: TextField(
                  controller: manualController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Number of items',
                    hintText: '1 - $remainingCount',
                    border: const OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(inputContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final value = int.tryParse(manualController.text);
                      if (value != null && value >= 1 && value <= remainingCount) {
                        updateValue(value.toDouble());
                        Navigator.pop(inputContext);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a value between 1 and $remainingCount'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    child: const Text('Set'),
                  ),
                ],
              ),
            );
          }

          return AlertDialog(
            title: const Text('Mark Items as Consumed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How many items did you consume?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                // Tappable number display
                Center(
                  child: InkWell(
                    onTap: showManualInputDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${sliderValue.round()}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit,
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tap to enter manually',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Slider
                Slider(
                  value: sliderValue,
                  min: 1.0,
                  max: remainingCount.toDouble(),
                  divisions: remainingCount > 1 ? remainingCount - 1 : 1,
                  label: sliderValue.round().toString(),
                  onChanged: updateValue,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Remaining: $remainingCount items',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '$remainingCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<ConsumptionQuotaBloc>().add(
                        CompleteQuota(
                          quotaId: quota.id,
                          itemCount: sliderValue.round(),
                        ),
                      );
                  Navigator.pop(dialogContext);
                },
                child: const Text('Consume'),
              ),
            ],
          );
        },
      ),
    );
  }
}
