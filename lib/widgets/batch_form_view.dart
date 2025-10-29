import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/inventory/inventory_barrel.dart';
import 'package:inventory_manager/bloc/consumption_quota/consumption_quota_barrel.dart';
import 'package:inventory_manager/models/food_item.dart';
import 'package:inventory_manager/models/inventory_batch.dart';
import 'package:inventory_manager/models/ingredient.dart';
import 'package:inventory_manager/repositories/recipe_repository.dart';
import 'package:inventory_manager/services/open_food_facts_service.dart';

class BatchFormView extends StatefulWidget {
  final String? barcode;
  final OpenFoodFactsProduct? productData;

  const BatchFormView({
    super.key,
    this.barcode,
    this.productData,
  });

  @override
  State<BatchFormView> createState() => _BatchFormViewState();
}

class _BatchFormViewState extends State<BatchFormView> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _countController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _kcalController = TextEditingController();

  final List<Ingredient> _selectedIngredients = [];
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;
  bool _isLoadingIngredients = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Set barcode if provided
    if (widget.barcode != null) {
      _barcodeController.text = widget.barcode!;
    }

    // Pre-fill form with product data if available
    if (widget.productData != null) {
      final product = widget.productData!;

      _nameController.text = product.displayName;

      if (product.productQuantityGrams != null) {
        _weightController.text = product.productQuantityGrams!.toStringAsFixed(1);
      } else {
        _weightController.text = '100';
      }

      // Set nutrition data if available
      if (product.carbohydrates100g != null) {
        _carbsController.text = product.carbohydrates100g!.toStringAsFixed(1);
      }
      if (product.fat100g != null) {
        _fatsController.text = product.fat100g!.toStringAsFixed(1);
      }
      if (product.proteins100g != null) {
        _proteinController.text = product.proteins100g!.toStringAsFixed(1);
      }
      if (product.energyKcal100g != null) {
        _kcalController.text = product.energyKcal100g!.toStringAsFixed(1);
      }

      // Load ingredient tags
      if (product.ingredientTags.isNotEmpty) {
        _loadIngredientsFromTags(product.ingredientTags);
      }
    } else {
      // Default values for manual entry
      _weightController.text = '100';
      _countController.text = '1';
      _carbsController.text = '0';
      _fatsController.text = '0';
      _proteinController.text = '0';
      _kcalController.text = '0';
    }

    // Default count
    if (_countController.text.isEmpty) {
      _countController.text = '1';
    }
  }

  Future<void> _loadIngredientsFromTags(List<String> tags) async {
    setState(() => _isLoadingIngredients = true);

    try {
      final repository = RepositoryProvider.of<RecipeRepository>(context, listen: false);

      for (final tagName in tags) {
        // Get or create ingredient in database
        final ingredient = await repository.getOrCreateIngredient(tagName);
        if (!_selectedIngredients.any((i) => i.id == ingredient.id)) {
          _selectedIngredients.add(ingredient);
        }
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load ingredient tags: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingIngredients = false);
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _countController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _proteinController.dispose();
    _kcalController.dispose();
    super.dispose();
  }

  Future<void> _selectExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  Future<void> _addIngredientTag() async {
    final repository = RepositoryProvider.of<RecipeRepository>(context, listen: false);

    // Get all available ingredients
    final allIngredients = await repository.getAllIngredients();

    if (!mounted) return;

    // Show dialog to select or create ingredient
    showDialog(
      context: context,
      builder: (dialogContext) => _IngredientSelectionDialog(
        availableIngredients: allIngredients,
        selectedIngredients: _selectedIngredients,
        onIngredientsSelected: (ingredients) {
          setState(() {
            _selectedIngredients.clear();
            _selectedIngredients.addAll(ingredients);
          });
        },
      ),
    );
  }

  Future<void> _saveBatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate nutrition data is provided
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fats = double.tryParse(_fatsController.text) ?? 0;
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final kcal = double.tryParse(_kcalController.text) ?? 0;

    if (carbs == 0 && fats == 0 && protein == 0 && kcal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least some nutrition information'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Create FoodItem
      final foodItem = FoodItem(
        id: _barcodeController.text.isNotEmpty
            ? _barcodeController.text
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        weightPerItemGrams: double.parse(_weightController.text),
        carbohydratesPerHundredGrams: carbs,
        fatsPerHundredGrams: fats,
        proteinPerHundredGrams: protein,
        kcalPerHundredGrams: kcal,
        ingredientIds: _selectedIngredients.map((i) => i.id!).toList(),
      );

      // Create InventoryBatch
      final count = int.parse(_countController.text);
      final batch = InventoryBatch(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        item: foodItem,
        count: count,
        initialCount: count,
        expirationDate: _expirationDate,
        dateAdded: DateTime.now(),
      );

      // Add to inventory via BLoC
      if (mounted) {
        context.read<InventoryBloc>().add(AddInventoryBatch(batch));

        // Generate consumption quotas for this batch
        context.read<ConsumptionQuotaBloc>().add(GenerateQuotasForBatch(batch));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save batch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Batch'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveBatch,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product Information Section
            Text(
              'Product Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barcode (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
              readOnly: widget.barcode != null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight per item (g) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _countController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: InkWell(
                onTap: _selectExpirationDate,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Expiration Date'),
                      Row(
                        children: [
                          Text(
                            '${_expirationDate.year}-${_expirationDate.month.toString().padLeft(2, '0')}-${_expirationDate.day.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Nutrition Information Section
            Text(
              'Nutrition (per 100g)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    decoration: const InputDecoration(
                      labelText: 'Carbs (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _fatsController,
                    decoration: const InputDecoration(
                      labelText: 'Fats (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    decoration: const InputDecoration(
                      labelText: 'Protein (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _kcalController,
                    decoration: const InputDecoration(
                      labelText: 'Calories (kcal)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Ingredient Tags Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ingredient Tags',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: _isLoadingIngredients ? null : _addIngredientTag,
                  icon: _isLoadingIngredients
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedIngredients.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No ingredient tags added yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedIngredients.map((ingredient) {
                  return Chip(
                    label: Text(ingredient.name),
                    onDeleted: () {
                      setState(() {
                        _selectedIngredients.remove(ingredient);
                      });
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),
            if (widget.productData != null && !widget.productData!.hasNutritionData)
              Card(
                color: Colors.orange.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Product found but nutrition data is incomplete. Please fill in manually.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for selecting or creating ingredient tags
class _IngredientSelectionDialog extends StatefulWidget {
  final List<Ingredient> availableIngredients;
  final List<Ingredient> selectedIngredients;
  final Function(List<Ingredient>) onIngredientsSelected;

  const _IngredientSelectionDialog({
    required this.availableIngredients,
    required this.selectedIngredients,
    required this.onIngredientsSelected,
  });

  @override
  State<_IngredientSelectionDialog> createState() => _IngredientSelectionDialogState();
}

class _IngredientSelectionDialogState extends State<_IngredientSelectionDialog> {
  final _searchController = TextEditingController();
  final _newIngredientController = TextEditingController();
  late List<Ingredient> _selectedIngredients;
  List<Ingredient> _filteredIngredients = [];

  @override
  void initState() {
    super.initState();
    _selectedIngredients = List.from(widget.selectedIngredients);
    _filteredIngredients = widget.availableIngredients;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newIngredientController.dispose();
    super.dispose();
  }

  void _filterIngredients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIngredients = widget.availableIngredients;
      } else {
        _filteredIngredients = widget.availableIngredients
            .where((i) => i.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _createNewIngredient() async {
    final name = _newIngredientController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an ingredient name'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final repository = RepositoryProvider.of<RecipeRepository>(context, listen: false);
      final newIngredient = await repository.getOrCreateIngredient(name);

      setState(() {
        // Add to selected ingredients
        if (!_selectedIngredients.any((i) => i.id == newIngredient.id)) {
          _selectedIngredients.add(newIngredient);
        }

        // Add to available ingredients list so it shows up
        if (!widget.availableIngredients.any((i) => i.id == newIngredient.id)) {
          widget.availableIngredients.add(newIngredient);
          _filteredIngredients = widget.availableIngredients;
        }

        _newIngredientController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created and selected "$name"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create ingredient: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Ingredient Tags'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search ingredients',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterIngredients,
            ),
            const SizedBox(height: 16),

            // Create new ingredient
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newIngredientController,
                    decoration: const InputDecoration(
                      labelText: 'Create new ingredient',
                      border: OutlineInputBorder(),
                      hintText: 'Type name and press + or Enter',
                      prefixIcon: Icon(Icons.add),
                    ),
                    onSubmitted: (_) => _createNewIngredient(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _createNewIngredient,
                  style: Theme.of(context).elevatedButtonTheme.style,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected ingredients
            if (_selectedIngredients.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selected:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedIngredients.map((ingredient) {
                  return Chip(
                    label: Text(ingredient.name),
                    onDeleted: () {
                      setState(() {
                        _selectedIngredients.remove(ingredient);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Available ingredients list
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Available:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredIngredients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.availableIngredients.isEmpty
                                ? 'No ingredients in database yet'
                                : 'No ingredients match your search',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create a new one using the field above',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredIngredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _filteredIngredients[index];
                        final isSelected = _selectedIngredients
                            .any((i) => i.id == ingredient.id);

                        return CheckboxListTile(
                          title: Text(ingredient.name),
                          value: isSelected,
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedIngredients.add(ingredient);
                              } else {
                                _selectedIngredients.removeWhere(
                                  (i) => i.id == ingredient.id,
                                );
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onIngredientsSelected(_selectedIngredients);
            Navigator.of(context).pop();
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}
