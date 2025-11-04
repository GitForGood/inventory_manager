import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/consumption_quota/consumption_quota_barrel.dart';
import 'package:inventory_manager/bloc/inventory/inventory_barrel.dart';
import 'package:inventory_manager/models/consumption_period.dart';
import 'package:inventory_manager/widgets/consumption_quota_card.dart';
import 'package:inventory_manager/widgets/outlined_card.dart';

class ConsumptionQuotaView extends StatefulWidget {
  const ConsumptionQuotaView({super.key});

  @override
  State<ConsumptionQuotaView> createState() => _ConsumptionQuotaViewState();
}

class _ConsumptionQuotaViewState extends State<ConsumptionQuotaView> {
  @override
  void initState() {
    super.initState();
    // Load quotas when view is first created
    Future.microtask(() {
      if (mounted) {
        context.read<ConsumptionQuotaBloc>().add(const LoadConsumptionQuotas());
      }
    });
  }

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
          if (state is ConsumptionQuotaInitial || state is ConsumptionQuotaLoading) {
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

                      return FoodItemQuotaCard(
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
            color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.05),
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

    return OutlinedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${state.overallProgress.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: colorScheme.secondary,
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
              backgroundColor: colorScheme.secondary.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
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
                color: colorScheme.tertiary,
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
