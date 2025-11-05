import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/inventory/inventory_barrel.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';
import 'package:inventory_manager/bloc/consumption_quota/consumption_quota_barrel.dart';
import 'package:inventory_manager/models/daily_calorie_target.dart';
import 'package:inventory_manager/models/inventory_batch.dart';
import 'package:inventory_manager/models/consumption_quota.dart';
import 'package:inventory_manager/services/upkeep_calculator_service.dart';
import 'package:inventory_manager/widgets/outlined_card.dart';
import 'package:inventory_manager/widgets/assist_chip.dart';
import 'package:inventory_manager/widgets/calorie_target_bottom_sheet.dart';

class UpkeepView extends StatefulWidget {
  const UpkeepView({super.key});

  @override
  State<UpkeepView> createState() => _UpkeepViewState();
}

class _UpkeepViewState extends State<UpkeepView> {
  final TextEditingController _purchaseCaloriesController = TextEditingController();
  final TextEditingController _daysUntilExpiryController = TextEditingController();
  PurchaseImpact? _calculatedImpact;

  @override
  void dispose() {
    _purchaseCaloriesController.dispose();
    _daysUntilExpiryController.dispose();
    super.dispose();
  }

  String _formatNumber(num number) {
    if (number is int) {
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
    // For doubles, format with 1 decimal place
    return number.toStringAsFixed(1).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _calculatePurchaseImpact({
    required List<InventoryBatch> batches,
    required int? dailyCalorieTarget,
    Map<String, List<ConsumptionQuota>>? quotasByFoodItem,
  }) {
    final purchaseCalories = double.tryParse(_purchaseCaloriesController.text);
    final daysUntilExpiry = int.tryParse(_daysUntilExpiryController.text);

    if (purchaseCalories == null || daysUntilExpiry == null || daysUntilExpiry <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter valid values for both fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _calculatedImpact = UpkeepCalculatorService.calculatePurchaseImpact(
        purchaseCalories: purchaseCalories,
        daysUntilExpiry: daysUntilExpiry,
        currentBatches: batches,
        dailyCalorieTarget: dailyCalorieTarget,
        quotasByFoodItem: quotasByFoodItem,
      );
    });
  }

  void _showCalorieTargetSheet(
    BuildContext context,
    DailyCalorieTarget? currentTarget,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CalorieTargetBottomSheet(
        currentTarget: currentTarget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Storage Upkeep', style: Theme.of(context).textTheme.headlineMedium),
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, inventoryState) {
          if (inventoryState is InventoryInitial || inventoryState is InventoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (inventoryState is InventoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    inventoryState.message,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else if (inventoryState is InventoryLoaded) {
            final batches = inventoryState.batches;

            return BlocBuilder<ConsumptionQuotaBloc, ConsumptionQuotaState>(
              builder: (context, quotaState) {
                final quotasByFoodItem = quotaState is ConsumptionQuotaLoaded
                    ? quotaState.quotasByFoodItem
                    : <String, List<ConsumptionQuota>>{};

                return BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, settingsState) {
                    final calorieTarget = settingsState is SettingsLoaded
                        ? settingsState.settings.dailyCalorieTarget
                        : null;
                    final dailyConsumption = settingsState is SettingsLoaded &&
                            settingsState.settings.dailyCalorieTarget is CalculatedCalorieTarget
                        ? (settingsState.settings.dailyCalorieTarget as CalculatedCalorieTarget)
                            .dailyConsumption
                        : null;

                    final storageDeficit = UpkeepCalculatorService.calculateStorageDeficit(
                      batches: batches,
                      dailyCalorieTarget: dailyConsumption,
                      targetDaysOfStorage: 30,
                    );

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildStorageStatusCard(
                          context,
                          storageDeficit,
                          calorieTarget,
                          dailyConsumption,
                        ),
                        const SizedBox(height: 16),
                        _buildRefillCalculatorCard(
                          context,
                          batches,
                          dailyConsumption,
                          quotasByFoodItem,
                        ),
                        if (_calculatedImpact != null) ...[
                          const SizedBox(height: 16),
                          _buildImpactResultCard(context, _calculatedImpact!),
                        ],
                      ],
                    );
                  },
                );
              },
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }

  Widget _buildStorageStatusCard(
    BuildContext context,
    StorageDeficit deficit,
    DailyCalorieTarget? calorieTarget,
    int? dailyConsumption,
  ) {
    final theme = Theme.of(context);
    final hasTarget = deficit.hasTarget;

    return OutlinedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current Storage Status',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AssistChip(
                  icon: Icons.local_fire_department,
                  labelText: '${_formatNumber(deficit.currentCalories.toInt())} kcal',
                ),
                if (deficit.daysUntilEmpty != null)
                  AssistChip(
                    icon: Icons.calendar_today,
                    labelText: '${deficit.daysUntilEmpty!.toStringAsFixed(1)} days',
                  ),
              ],
            ),
            if (!hasTarget) ...[
              const Divider(),
              InkWell(
                onTap: () => _showCalorieTargetSheet(context, calorieTarget),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Set daily calorie target to see recommendations',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Divider(),
              // Target comparison
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '30-Day Target: ${_formatNumber(deficit.targetCalories.toInt())} kcal',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (deficit.isAboveTarget) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Storage is above 30-day target by ${_formatNumber((deficit.currentCalories - deficit.targetCalories).toInt())} kcal',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Need ${_formatNumber(deficit.deficitCalories.toInt())} kcal to reach 30-day target',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current storage will last ${deficit.daysUntilEmpty?.toStringAsFixed(1) ?? "?"} days at your current consumption rate of ${_formatNumber(dailyConsumption ?? 0)} kcal/day',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRefillCalculatorCard(
    BuildContext context,
    List<InventoryBatch> batches,
    int? dailyConsumption,
    Map<String, List<ConsumptionQuota>> quotasByFoodItem,
  ) {
    final theme = Theme.of(context);

    return OutlinedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Purchase Impact Calculator',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Estimate how much you need to consume per day/month to finish items before they expire',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _purchaseCaloriesController,
              decoration: InputDecoration(
                labelText: 'Purchase Calories (kcal)',
                hintText: 'e.g., 20000',
                prefixIcon: const Icon(Icons.local_fire_department),
                border: const OutlineInputBorder(),
                suffixText: 'kcal',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _daysUntilExpiryController,
              decoration: InputDecoration(
                labelText: 'Days Until Expiry',
                hintText: 'e.g., 365',
                prefixIcon: const Icon(Icons.calendar_today),
                border: const OutlineInputBorder(),
                suffixText: 'days',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _calculatePurchaseImpact(
                  batches: batches,
                  dailyCalorieTarget: dailyConsumption,
                  quotasByFoodItem: quotasByFoodItem,
                ),
                icon: const Icon(Icons.calculate),
                label: const Text('Calculate Impact'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactResultCard(BuildContext context, PurchaseImpact impact) {
    final theme = Theme.of(context);

    return OutlinedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Purchase Impact',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildImpactRow(
              context,
              'Purchase',
              '${_formatNumber(impact.purchaseCalories.toInt())} kcal',
              Icons.shopping_cart,
            ),
            const SizedBox(height: 8),
            _buildImpactRow(
              context,
              'Days Until Expiry',
              '${impact.daysUntilExpiry} days',
              Icons.event,
            ),
            const Divider(),
            _buildImpactRow(
              context,
              'Daily Consumption Needed',
              '${_formatNumber(impact.dailyQuotaIncrease)} kcal/day',
              Icons.trending_up,
              highlighted: true,
            ),
            const SizedBox(height: 8),
            _buildImpactRow(
              context,
              'Monthly Consumption Needed',
              '${_formatNumber(impact.monthlyQuotaIncrease)} kcal/month',
              Icons.calendar_month,
              highlighted: true,
            ),
            const Divider(),
            _buildImpactRow(
              context,
              'New Total Storage',
              '${_formatNumber(impact.newTotalCalories.toInt())} kcal',
              Icons.inventory,
            ),
            if (impact.newDaysUntilEmpty != null) ...[
              const SizedBox(height: 8),
              _buildImpactRow(
                context,
                'New Days Until Empty',
                '${impact.newDaysUntilEmpty!.toStringAsFixed(1)} days',
                Icons.hourglass_bottom,
              ),
            ],
            if (impact.currentConsumptionRate != null && impact.newConsumptionRate != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Quota-Based Consumption Rates',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatNumber(impact.currentConsumptionRate!.dailyCalories)} kcal/day',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_formatNumber(impact.currentConsumptionRate!.monthlyCalories)} kcal/month',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'After Purchase',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatNumber(impact.newConsumptionRate!.dailyCalories)} kcal/day',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                '${_formatNumber(impact.newConsumptionRate!.monthlyCalories)} kcal/month',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This shows how your consumption quotas (generated to keep food fresh) will change',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            if (impact.suggestedPeriod != null) ...[
              const Divider(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Suggested consumption period: ${impact.suggestedPeriod!.name.toUpperCase()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImpactRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool highlighted = false,
  }) {
    final theme = Theme.of(context);
    final textColor = highlighted ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, size: 20, color: textColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: highlighted ? FontWeight.bold : null,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
