import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/inventory/inventory_barrel.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';
import 'package:inventory_manager/bloc/consumption_quota/consumption_quota_barrel.dart';
import 'package:inventory_manager/models/daily_calorie_target.dart';
import 'package:inventory_manager/models/inventory_batch.dart';
import 'package:inventory_manager/models/consumption_quota.dart';
import 'package:inventory_manager/models/food_item.dart';
import 'package:inventory_manager/services/upkeep_calculator_service.dart';
import 'package:inventory_manager/widgets/outlined_card.dart';
import 'package:inventory_manager/widgets/assist_chip.dart';
import 'package:inventory_manager/widgets/calorie_target_bottom_sheet.dart';

/// Shopping cart item
class ShoppingCartItem {
  final FoodItem foodItem;
  final int quantity;

  const ShoppingCartItem({
    required this.foodItem,
    required this.quantity,
  });

  double get totalCalories => foodItem.getKcalForItems(quantity);
}

class UpkeepView extends StatefulWidget {
  const UpkeepView({super.key});

  @override
  State<UpkeepView> createState() => _UpkeepViewState();
}

class _UpkeepViewState extends State<UpkeepView> {
  final ScrollController _scrollController = ScrollController();
  final List<ShoppingCartItem> _shoppingCart = [];
  DateTime? _selectedExpiryDate;
  PurchaseImpact? _calculatedImpact;
  final GlobalKey _impactCardKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
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

  void _addToCart(FoodItem foodItem, int quantity) {
    setState(() {
      _shoppingCart.add(ShoppingCartItem(
        foodItem: foodItem,
        quantity: quantity,
      ));
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _shoppingCart.removeAt(index);
    });
  }

  void _clearCart() {
    setState(() {
      _shoppingCart.clear();
    });
  }

  double _getTotalCartCalories() {
    return _shoppingCart.fold(0.0, (sum, item) => sum + item.totalCalories);
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
      helpText: 'Select expiry date',
    );

    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  void _calculatePurchaseImpact({
    required List<InventoryBatch> batches,
    required int? dailyCalorieTarget,
    Map<String, List<ConsumptionQuota>>? quotasByFoodItem,
  }) {
    if (_shoppingCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add items to your shopping cart'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an expiry date'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final purchaseCalories = _getTotalCartCalories();
    final daysUntilExpiry = _selectedExpiryDate!.difference(DateTime.now()).inDays;

    if (daysUntilExpiry <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expiry date must be in the future'),
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

    // Scroll to impact card after calculation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_impactCardKey.currentContext != null) {
        Scrollable.ensureVisible(
          _impactCardKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<FoodItem?> _showCreateItemDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();

    return showDialog<FoodItem>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., Canned Beans',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories per Item',
                border: OutlineInputBorder(),
                hintText: 'e.g., 250',
                suffixText: 'kcal',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final calories = int.tryParse(caloriesController.text);

              if (name.isNotEmpty && calories != null && calories > 0) {
                // Create a placeholder food item
                final newItem = FoodItem(
                  id: 'placeholder_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  weightPerItemGrams: 100, // Placeholder weight
                  kcalPerHundredGrams: calories.toDouble(),
                  ingredientIds: [],
                );
                Navigator.pop(dialogContext, newItem);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, List<InventoryBatch> batches) {
    // Get unique food items from batches
    final uniqueFoodItems = <String, FoodItem>{};
    for (final batch in batches) {
      uniqueFoodItems[batch.item.id] = batch.item;
    }

    final foodItems = uniqueFoodItems.values.toList()..sort((a, b) => a.name.compareTo(b.name));

    // Add placeholder for creating new item
    final createNewPlaceholder = FoodItem(
      id: '__create_new__',
      name: 'Create New Item...',
      weightPerItemGrams: 0,
      kcalPerHundredGrams: 0,
      ingredientIds: [],
    );

    FoodItem? selectedItem;
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Item to Cart'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FoodItem>(
                  decoration: const InputDecoration(
                    labelText: 'Select Food Item',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: selectedItem,
                  items: [
                    DropdownMenuItem(
                      value: createNewPlaceholder,
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Create New Item...',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (foodItems.isNotEmpty) const DropdownMenuItem(enabled: false, child: Divider()),
                    ...foodItems.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item.name),
                      );
                    }),
                  ],
                  onChanged: (value) async {
                    if (value?.id == '__create_new__') {
                      // Show create new item dialog
                      final newItem = await _showCreateItemDialog(context);
                      if (newItem != null) {
                        setDialogState(() {
                          selectedItem = newItem;
                          foodItems.add(newItem);
                          foodItems.sort((a, b) => a.name.compareTo(b.name));
                        });
                      }
                    } else {
                      setDialogState(() {
                        selectedItem = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: const OutlineInputBorder(),
                    suffixText: selectedItem != null && selectedItem!.id != '__create_new__'
                        ? '${_formatNumber(selectedItem!.getKcalForItems(int.tryParse(quantityController.text) ?? 1))} kcal'
                        : 'items',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    setDialogState(() {}); // Refresh to update calorie display
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (selectedItem != null && selectedItem!.id != '__create_new__') {
                  final quantity = int.tryParse(quantityController.text);
                  if (quantity != null && quantity > 0) {
                    _addToCart(selectedItem!, quantity);
                    Navigator.pop(dialogContext);
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  String _generateCSV() {
    final buffer = StringBuffer();
    buffer.writeln('Item,Quantity,Calories per Item,Total Calories');

    for (final item in _shoppingCart) {
      buffer.writeln(
        '"${item.foodItem.name}",${item.quantity},${_formatNumber(item.foodItem.getKcalForItems(1))},${_formatNumber(item.totalCalories)}',
      );
    }

    buffer.writeln();
    buffer.writeln('"Total","","",${_formatNumber(_getTotalCartCalories())}');

    if (_selectedExpiryDate != null) {
      buffer.writeln();
      buffer.writeln('"Expiry Date","${_selectedExpiryDate!.toLocal().toString().split(' ')[0]}"');
    }

    return buffer.toString();
  }

  void _exportAsCSV() {
    final csv = _generateCSV();
    // For web/desktop: Copy to clipboard
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shopping list copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
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
                    final desiredDays = settingsState is SettingsLoaded &&
                            settingsState.settings.dailyCalorieTarget is CalculatedCalorieTarget
                        ? (settingsState.settings.dailyCalorieTarget as CalculatedCalorieTarget).days
                        : 30; // Default fallback

                    final storageDeficit = UpkeepCalculatorService.calculateStorageDeficit(
                      batches: batches,
                      dailyCalorieTarget: dailyConsumption,
                      targetDaysOfStorage: desiredDays,
                    );

                    return ListView(
                      controller: _scrollController,
                      //padding: const EdgeInsets.all(16),
                      children: [
                        _buildStorageStatusCard(
                          context,
                          storageDeficit,
                          calorieTarget,
                          dailyConsumption,
                          desiredDays,
                        ),
                        //const SizedBox(height: 16),
                        _buildShoppingCartCard(context, batches),
                        //const SizedBox(height: 16),
                        _buildCalculatorActionsCard(
                          context,
                          batches,
                          dailyConsumption,
                          quotasByFoodItem,
                        ),
                        if (_calculatedImpact != null) ...[
                          //const SizedBox(height: 16),
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
    int desiredDays,
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
                      '$desiredDays-Day Target: ${_formatNumber(deficit.targetCalories.toInt())} kcal',
                      style: theme.textTheme.bodyLarge,
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
                          'Storage is above $desiredDays-day target by ${_formatNumber((deficit.currentCalories - deficit.targetCalories).toInt())} kcal',
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
                          'Need ${_formatNumber(deficit.deficitCalories.toInt())} kcal to reach $desiredDays-day target',
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

  Widget _buildShoppingCartCard(BuildContext context, List<InventoryBatch> batches) {
    final theme = Theme.of(context);

    return OutlinedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Shopping Cart',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_shoppingCart.isNotEmpty)
                  FilledButton.tonalIcon(
                    onPressed: _clearCart,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_shoppingCart.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No items in cart',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _shoppingCart.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _shoppingCart[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.foodItem.name),
                    subtitle: Text(
                      '${item.quantity} items • ${_formatNumber(item.totalCalories)} kcal',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeFromCart(index),
                      tooltip: 'Remove',
                    ),
                  );
                },
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_formatNumber(_getTotalCartCalories())} kcal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shoppingCart.isNotEmpty ? _exportAsCSV : null,
                      icon: const Icon(Icons.file_download),
                      label: const Text('Export CSV'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAddItemDialog(context, batches),
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorActionsCard(
    BuildContext context,
    List<InventoryBatch> batches,
    int? dailyConsumption,
    Map<String, List<ConsumptionQuota>> quotasByFoodItem,
  ) {
    final theme = Theme.of(context);
    final daysUntilExpiry = _selectedExpiryDate?.difference(DateTime.now()).inDays;

    return OutlinedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Expiry Date',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectExpiryDate(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedExpiryDate == null
                                ? 'Select expiry date'
                                : 'Expiry: ${_selectedExpiryDate!.toLocal().toString().split(' ')[0]}',
                            style: theme.textTheme.bodyLarge,
                          ),
                          if (daysUntilExpiry != null)
                            Text(
                              '$daysUntilExpiry days from today',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
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
      key: _impactCardKey,
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
