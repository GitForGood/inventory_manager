import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/consumption_quota/consumption_quota_barrel.dart';
import 'package:inventory_manager/bloc/inventory/inventory_barrel.dart';
import 'package:inventory_manager/models/consumption_period.dart';
import 'package:inventory_manager/models/consumption_quota.dart';
import 'package:intl/intl.dart';

class ConsumptionQuotaView extends StatelessWidget {
  const ConsumptionQuotaView({super.key});

  void _showRegenerateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Regenerate All Quotas?'),
        content: const Text(
          'This will delete all existing quotas and regenerate them from your current batches. \n\n'
          'Any consumption progress will be lost. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ConsumptionQuotaBloc>().add(
                    const ClearAndRegenerateAllQuotas(),
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumption Quotas'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'refresh') {
                context.read<ConsumptionQuotaBloc>().add(const RefreshQuotas());
              } else if (value == 'regenerate') {
                _showRegenerateDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 12),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'regenerate',
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high),
                    SizedBox(width: 12),
                    Text('Regenerate All Quotas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocListener<ConsumptionQuotaBloc, ConsumptionQuotaState>(
        listener: (context, state) {
          // Show error messages
          if (state is ConsumptionQuotaError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }

          // When quotas are updated, reload inventory to reflect changes
          if (state is ConsumptionQuotaLoaded) {
            context.read<InventoryBloc>().add(const LoadInventory());
          }
        },
        child: BlocBuilder<ConsumptionQuotaBloc, ConsumptionQuotaState>(
          builder: (context, state) {
          if (state is ConsumptionQuotaInitial) {
            // Load current period quotas on first build
            context.read<ConsumptionQuotaBloc>().add(const LoadCurrentPeriodQuotas());
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ConsumptionQuotaLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ConsumptionQuotaError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading quotas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ConsumptionQuotaBloc>().add(const RefreshQuotas());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ConsumptionQuotaLoaded) {
            if (state.quotasByFoodItem.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No consumption quotas yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some inventory batches to get started',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _PeriodSelector(selectedPeriod: state.selectedPeriod),
                _ProgressOverview(state: state),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.quotasByFoodItem.length,
                    itemBuilder: (context, index) {
                      final foodItemName = state.quotasByFoodItem.keys.elementAt(index);
                      final quotas = state.quotasByFoodItem[foodItemName]!;

                      return _FoodItemQuotaCard(
                        foodItemName: foodItemName,
                        quotas: quotas,
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final ConsumptionPeriod selectedPeriod;

  const _PeriodSelector({required this.selectedPeriod});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 20),
          const SizedBox(width: 12),
          const Text(
            'Period:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<ConsumptionPeriod>(
              value: selectedPeriod,
              isExpanded: true,
              underline: const SizedBox(),
              items: ConsumptionPeriod.values.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period.displayName),
                );
              }).toList(),
              onChanged: (newPeriod) {
                if (newPeriod != null && newPeriod != selectedPeriod) {
                  context.read<ConsumptionQuotaBloc>().add(
                        ChangePreferredPeriod(newPeriod),
                      );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  final ConsumptionQuotaLoaded state;

  const _ProgressOverview({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: EdgeInsetsGeometry.all(16),
        child: Column(
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${state.overallProgress.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.overallProgress / 100,
              minHeight: 8,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatusChip(
                icon: Icons.check_circle,
                label: 'Completed',
                count: state.completedQuotas.length,
                color: const Color(0xFF66BB6A), // Success green
              ),
              _StatusChip(
                icon: Icons.warning,
                label: 'Overdue',
                count: state.overdueQuotas.length,
                color: colorScheme.error,
              ),
              _StatusChip(
                icon: Icons.access_time,
                label: 'Due Soon',
                count: state.dueSoonQuotas.length,
                color: colorScheme.secondary,
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _FoodItemQuotaCard extends StatelessWidget {
  final String foodItemName;
  final List<ConsumptionQuota> quotas;

  const _FoodItemQuotaCard({
    required this.foodItemName,
    required this.quotas,
  });

  @override
  Widget build(BuildContext context) {
    // With the new system, there should only be one quota per food item
    // But we'll handle the edge case of multiple quotas gracefully
    final quota = quotas.isNotEmpty ? quotas.first : null;

    if (quota == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final progress = quota.progressPercentage / 100;

    Color statusColor = colorScheme.onSurfaceVariant;
    IconData statusIcon = Icons.circle_outlined;
    String statusText = 'Pending';

    if (quota.isCompleted) {
      statusColor = const Color(0xFF66BB6A); // Success green
      statusIcon = Icons.check_circle;
      statusText = 'Completed';
    } else if (quota.isOverdue) {
      statusColor = colorScheme.error;
      statusIcon = Icons.error;
      statusText = 'Overdue';
    } else if (quota.isDueSoon) {
      statusColor = colorScheme.secondary;
      statusIcon = Icons.warning;
      statusText = 'Due Soon';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        foodItemName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
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
                if (!quota.isCompleted)
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: colorScheme.primary,
                    iconSize: 32,
                    onPressed: () {
                      _showIncrementDialog(context, quota);
                    },
                  ),
                if (quota.isCompleted)
                  Icon(Icons.check, size: 32, color: statusColor,),
              ],
            ),
            if (!quota.isCompleted)
              const SizedBox(height: 12),
            // Progress
            if (!quota.isCompleted)
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
                            value: progress,
                            minHeight: 8,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showHideDialog(BuildContext context, ConsumptionQuota quota) {
    
  }
  void _showIncrementDialog(BuildContext context, ConsumptionQuota quota) {
    int incrementValue = 1;
    final remainingCount = quota.remainingCount;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Consume ${quota.foodItemName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How many items did you consume?'),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      incrementValue.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                    color: Theme.of(context).colorScheme.primary,
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

                // Show success feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Consumed $incrementValue ${incrementValue == 1 ? 'item' : 'items'} from quota'),
                    backgroundColor: const Color(0xFF66BB6A),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
