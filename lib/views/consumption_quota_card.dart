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
      child: InkWell(
        onTap: isCollapsed
            ? () {
                // Tapping collapsed card does nothing
              }
            : null,
        borderRadius: BorderRadius.circular(12),
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
                          : colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      color: isCollapsed
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
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
                    // Active quota buttons
                    // Bulk complete button
                    IconButton(
                      icon: const Icon(Icons.done_all),
                      color: colorScheme.tertiary,
                      iconSize: 28,
                      tooltip: 'Complete all remaining',
                      onPressed: () {
                        _showBulkCompleteDialog(context, quota);
                      },
                    ),
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
                                  color: colorScheme.onSurface,
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
                                  colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBulkCompleteDialog(BuildContext context, ConsumptionQuota quota) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete Quota'),
        content: Text(
          'Mark all ${quota.remainingCount} remaining items as consumed?\n\n'
          'This will consume ${quota.remainingCount} items from your inventory.',
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
                      itemCount: quota.remainingCount,
                    ),
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showIncrementDialog(BuildContext context, ConsumptionQuota quota) {
    int incrementValue = 1;
    final remainingCount = quota.remainingCount;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: incrementValue > 1
                        ? () {
                            setState(() {
                              incrementValue--;
                            });
                          }
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$incrementValue',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: incrementValue < remainingCount
                        ? () {
                            setState(() {
                              incrementValue++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Remaining: $remainingCount items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
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
                        itemCount: incrementValue,
                      ),
                    );
                Navigator.pop(dialogContext);
              },
              child: const Text('Consume'),
            ),
          ],
        ),
      ),
    );
  }
}
