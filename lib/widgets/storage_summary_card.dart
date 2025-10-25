import 'package:flutter/material.dart';
import 'package:inventory_manager/services/storage_calculator_service.dart';
import 'package:inventory_manager/widgets/summary_item.dart';
import 'package:material_symbols_icons/symbols.dart';

class StorageSummaryCard extends StatelessWidget {
  final StorageStatus status;

  const StorageSummaryCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                Text(
                  'Storage Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  color: Theme.of(context).colorScheme.primary /*status.estimatedDays < 7
                      ? Colors.red
                      : status.estimatedDays < 14
                      ? Colors.orange
                      : Colors.green,*/
                ),
              ],
            ),
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
  }
}