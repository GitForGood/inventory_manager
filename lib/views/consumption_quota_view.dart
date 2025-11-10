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
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load quotas when view is first created
    Future.microtask(() {
      if (mounted) {
        context.read<ConsumptionQuotaBloc>().add(const LoadConsumptionQuotas());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show FAB when scrolled down more than 200 pixels
    final shouldShow = _scrollController.offset > 200;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
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

  void _showChangePeriodDialog(BuildContext context) {
    final state = context.read<ConsumptionQuotaBloc>().state;
    ConsumptionPeriod currentPeriod = ConsumptionPeriod.weekly;

    if (state is ConsumptionQuotaLoaded) {
      currentPeriod = state.selectedPeriod;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Consumption Period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select how often you want your consumption quotas to reset:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...ConsumptionPeriod.values.map((period) => RadioListTile<ConsumptionPeriod>(
                title: Text(period.displayName),
                subtitle: Text(_getPeriodDescription(period)),
                value: period,
                groupValue: currentPeriod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      currentPeriod = value;
                    });
                  }
                },
              )),
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
                  RegenerateAllQuotas(currentPeriod),
                );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Period changed to ${currentPeriod.displayName}'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodDescription(ConsumptionPeriod period) {
    switch (period) {
      case ConsumptionPeriod.weekly:
        return 'Monday to Sunday';
      case ConsumptionPeriod.monthly:
        return 'First to last day of month';
      case ConsumptionPeriod.quarterly:
        return 'Three-month periods';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consumption Quotas', style: Theme.of(context).textTheme.headlineMedium,),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'refresh') {
                context.read<ConsumptionQuotaBloc>().add(const RefreshQuotas());
              } else if (value == 'regenerate') {
                _showRegenerateDialog(context);
              } else if (value == 'change_period') {
                _showChangePeriodDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_period',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 12),
                    Text('Change Period'),
                  ],
                ),
              ),
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
      body: Stack(
        children: [
          BlocListener<ConsumptionQuotaBloc, ConsumptionQuotaState>(
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
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Consumption Quotas Yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'To get started with consumption quotas:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      _EmptyStateHintCard(
                        icon: Icons.add_shopping_cart,
                        title: '1. Add inventory',
                        description: 'Create some food items and add batches to your inventory',
                      ),
                      const SizedBox(height: 12),
                      _EmptyStateHintCard(
                        icon: Icons.settings,
                        title: '2. Check your settings',
                        description: 'Adjust your desired consumption period in settings if needed',
                      ),
                      const SizedBox(height: 12),
                      _EmptyStateHintCard(
                        icon: Icons.auto_fix_high,
                        title: '3. Quotas generate automatically',
                        description: 'Quotas will appear here once you have inventory',
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: state.quotasByFoodItem.length + 2, // +2 for summary and header
              itemBuilder: (context, index) {
                // Summary card (Progress Overview)
                if (index == 0) {
                  return _ProgressOverview(state: state);
                }

                // Header with spacing
                if (index == 1) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Quotas', style: Theme.of(context).textTheme.headlineSmall),
                      ),
                    ],
                  );
                }

                // List items
                final itemIndex = index - 2;
                final foodItemName = state.quotasByFoodItem.keys.elementAt(itemIndex);
                final quotas = state.quotasByFoodItem[foodItemName]!;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: FoodItemQuotaCard(
                    foodItemName: foodItemName,
                    quotas: quotas,
                  ),
                );
              },
            );
          }

          return const SizedBox();
        },
            ),
          ),
          // Scroll-to-top FAB
          if (_showScrollToTop)
            Positioned(
              top: 8,
              left: MediaQuery.of(context).size.width / 2 - 20,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _scrollToTop,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      size: 24,
                    ),
                  ),
                ),
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
        ],
        ),
      ),
    );
  }
}

class _EmptyStateHintCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyStateHintCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
