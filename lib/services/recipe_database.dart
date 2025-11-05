import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:inventory_manager/models/recipe.dart';
import 'package:inventory_manager/models/ingredient.dart';
import 'package:inventory_manager/models/unit.dart';
import 'package:inventory_manager/models/recipe_ingredient.dart';
import 'package:inventory_manager/models/food_item.dart';
import 'package:inventory_manager/models/inventory_batch.dart';
import 'package:inventory_manager/models/consumption_quota.dart';

class RecipeDatabase {
  static final RecipeDatabase instance = RecipeDatabase._init();
  static Database? _database;

  RecipeDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recipes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Recipes table
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        readyInMinutes INTEGER NOT NULL,
        servings INTEGER NOT NULL,
        imageUrl TEXT,
        summary TEXT,
        isFavorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Ingredients table
    await db.execute('''
      CREATE TABLE ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Units table
    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Recipe ingredients junction table
    await db.execute('''
      CREATE TABLE recipe_ingredients (
        recipeId INTEGER NOT NULL,
        ingredientId INTEGER NOT NULL,
        amount REAL NOT NULL,
        unitId INTEGER NOT NULL,
        PRIMARY KEY (recipeId, ingredientId),
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE,
        FOREIGN KEY (ingredientId) REFERENCES ingredients (id),
        FOREIGN KEY (unitId) REFERENCES units (id)
      )
    ''');

    // Recipe steps table
    await db.execute('''
      CREATE TABLE recipe_steps (
        recipeId INTEGER NOT NULL,
        stepNumber INTEGER NOT NULL,
        instruction TEXT NOT NULL,
        PRIMARY KEY (recipeId, stepNumber),
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');

    // Food item ingredients junction table (for tagging food items with ingredients)
    await db.execute('''
      CREATE TABLE food_item_ingredients (
        foodItemId TEXT NOT NULL,
        ingredientId INTEGER NOT NULL,
        PRIMARY KEY (foodItemId, ingredientId),
        FOREIGN KEY (ingredientId) REFERENCES ingredients (id)
      )
    ''');

    // Food items table
    await db.execute('''
      CREATE TABLE food_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        weightPerItemGrams REAL NOT NULL,
        kcalPerHundredGrams REAL NOT NULL
      )
    ''');

    // Inventory batches table
    await db.execute('''
      CREATE TABLE inventory_batches (
        id TEXT PRIMARY KEY,
        foodItemId TEXT NOT NULL,
        count INTEGER NOT NULL,
        initialCount INTEGER NOT NULL,
        expirationDate TEXT NOT NULL,
        dateAdded TEXT NOT NULL,
        FOREIGN KEY (foodItemId) REFERENCES food_items (id) ON DELETE CASCADE
      )
    ''');

    // Consumption quotas table
    await db.execute('''
      CREATE TABLE consumption_quotas (
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        foodItemId TEXT NOT NULL,
        foodItemName TEXT NOT NULL,
        targetDate TEXT NOT NULL,
        targetCount INTEGER NOT NULL,
        consumedCount INTEGER NOT NULL DEFAULT 0,
        lastConsumed TEXT,
        FOREIGN KEY (batchId) REFERENCES inventory_batches (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_recipes_favorite ON recipes(isFavorite)');
    await db.execute('CREATE INDEX idx_recipe_ingredients_recipe ON recipe_ingredients(recipeId)');
    await db.execute('CREATE INDEX idx_recipe_ingredients_ingredient ON recipe_ingredients(ingredientId)');
    await db.execute('CREATE INDEX idx_recipe_steps_recipe ON recipe_steps(recipeId)');
    await db.execute('CREATE INDEX idx_food_item_ingredients_food ON food_item_ingredients(foodItemId)');
    await db.execute('CREATE INDEX idx_food_item_ingredients_ingredient ON food_item_ingredients(ingredientId)');
    await db.execute('CREATE INDEX idx_inventory_batches_food_item ON inventory_batches(foodItemId)');
    await db.execute('CREATE INDEX idx_inventory_batches_expiration ON inventory_batches(expirationDate)');
    await db.execute('CREATE INDEX idx_consumption_quotas_batch ON consumption_quotas(batchId)');
    await db.execute('CREATE INDEX idx_consumption_quotas_food_item ON consumption_quotas(foodItemId)');
    await db.execute('CREATE INDEX idx_consumption_quotas_target_date ON consumption_quotas(targetDate)');

    // Insert common units
    await _insertCommonUnits(db);
  }

  /// Recreate all database tables from scratch (destructive!)
  /// This drops all existing tables and recreates them
  Future<void> recreateAllTables() async {
    final db = await database;

    // Drop all tables
    await db.execute('DROP TABLE IF EXISTS recipe_steps');
    await db.execute('DROP TABLE IF EXISTS recipe_ingredients');
    await db.execute('DROP TABLE IF EXISTS recipes');
    await db.execute('DROP TABLE IF EXISTS consumption_quotas');
    await db.execute('DROP TABLE IF EXISTS inventory_batches');
    await db.execute('DROP TABLE IF EXISTS food_item_ingredients');
    await db.execute('DROP TABLE IF EXISTS food_items');
    await db.execute('DROP TABLE IF EXISTS ingredients');
    await db.execute('DROP TABLE IF EXISTS units');

    // Recreate all tables
    await _createDB(db, 1);
  }

  Future<void> _insertCommonUnits(Database db) async {
    final commonUnits = [
      'piece', 'g', 'kg', 'ml', 'l', 'tsp', 'tbsp', 'cup', 'oz', 'lb',
      'pinch', 'handful', 'slice', 'clove', 'can', 'package', 'bunch'
    ];

    for (final unit in commonUnits) {
      await db.insert('units', {'name': unit}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ===== INGREDIENT OPERATIONS =====

  Future<Ingredient> createIngredient(String name) async {
    final db = await database;
    final id = await db.insert(
      'ingredients',
      {'name': name.toLowerCase()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    if (id > 0) {
      return Ingredient(id: id, name: name);
    } else {
      // Ingredient already exists, fetch it
      final result = await db.query(
        'ingredients',
        where: 'name = ?',
        whereArgs: [name.toLowerCase()],
      );
      return Ingredient.fromMap(result.first);
    }
  }

  Future<Ingredient?> getIngredientByName(String name) async {
    final db = await database;
    final results = await db.query(
      'ingredients',
      where: 'name = ?',
      whereArgs: [name.toLowerCase()],
    );

    if (results.isNotEmpty) {
      return Ingredient.fromMap(results.first);
    }
    return null;
  }

  Future<List<Ingredient>> getAllIngredients() async {
    final db = await database;
    final results = await db.query('ingredients', orderBy: 'name ASC');
    return results.map((map) => Ingredient.fromMap(map)).toList();
  }

  Future<List<Ingredient>> searchIngredients(String query) async {
    final db = await database;
    final results = await db.query(
      'ingredients',
      where: 'name LIKE ?',
      whereArgs: ['%${query.toLowerCase()}%'],
      orderBy: 'name ASC',
    );
    return results.map((map) => Ingredient.fromMap(map)).toList();
  }

  // ===== UNIT OPERATIONS =====

  Future<Unit> createUnit(String name) async {
    final db = await database;
    final id = await db.insert(
      'units',
      {'name': name.toLowerCase()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    if (id > 0) {
      return Unit(id: id, name: name);
    } else {
      // Unit already exists, fetch it
      final result = await db.query(
        'units',
        where: 'name = ?',
        whereArgs: [name.toLowerCase()],
      );
      return Unit.fromMap(result.first);
    }
  }

  Future<Unit?> getUnitByName(String name) async {
    final db = await database;
    final results = await db.query(
      'units',
      where: 'name = ?',
      whereArgs: [name.toLowerCase()],
    );

    if (results.isNotEmpty) {
      return Unit.fromMap(results.first);
    }
    return null;
  }

  Future<List<Unit>> getAllUnits() async {
    final db = await database;
    final results = await db.query('units', orderBy: 'name ASC');
    return results.map((map) => Unit.fromMap(map)).toList();
  }

  // ===== RECIPE OPERATIONS =====

  Future<Recipe> createRecipe(Recipe recipe) async {
    final db = await database;

    // Insert recipe
    final recipeId = await db.insert('recipes', recipe.toMap());

    // Insert ingredients
    for (final ingredient in recipe.ingredients) {
      await db.insert('recipe_ingredients', {
        'recipeId': recipeId,
        'ingredientId': ingredient.ingredientId,
        'amount': ingredient.amount,
        'unitId': ingredient.unitId,
      });
    }

    // Insert steps
    for (int i = 0; i < recipe.instructions.length; i++) {
      await db.insert('recipe_steps', {
        'recipeId': recipeId,
        'stepNumber': i + 1,
        'instruction': recipe.instructions[i],
      });
    }

    return recipe.copyWith(id: recipeId);
  }

  Future<Recipe?> getRecipe(int id) async {
    final db = await database;

    // Get recipe
    final recipeResults = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (recipeResults.isEmpty) return null;

    // Get ingredients with details
    final ingredientResults = await db.rawQuery('''
      SELECT ri.recipeId, ri.ingredientId, ri.amount, ri.unitId,
             i.name as ingredientName, u.name as unitName
      FROM recipe_ingredients ri
      JOIN ingredients i ON ri.ingredientId = i.id
      JOIN units u ON ri.unitId = u.id
      WHERE ri.recipeId = ?
    ''', [id]);

    final ingredients = ingredientResults
        .map((map) => RecipeIngredient.fromMapWithDetails(map))
        .toList();

    // Get steps
    final stepResults = await db.query(
      'recipe_steps',
      where: 'recipeId = ?',
      whereArgs: [id],
      orderBy: 'stepNumber ASC',
    );

    final instructions = stepResults
        .map((map) => map['instruction'] as String)
        .toList();

    return Recipe.fromMap(
      recipeResults.first,
      ingredients: ingredients,
      instructions: instructions,
    );
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final results = await db.query('recipes', orderBy: 'title ASC');

    final recipes = <Recipe>[];
    for (final recipeMap in results) {
      final recipe = await getRecipe(recipeMap['id'] as int);
      if (recipe != null) {
        recipes.add(recipe);
      }
    }
    return recipes;
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    final db = await database;
    final results = await db.query(
      'recipes',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'title ASC',
    );

    final recipes = <Recipe>[];
    for (final recipeMap in results) {
      final recipe = await getRecipe(recipeMap['id'] as int);
      if (recipe != null) {
        recipes.add(recipe);
      }
    }
    return recipes;
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    final db = await database;
    final results = await db.query(
      'recipes',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'title ASC',
    );

    final recipes = <Recipe>[];
    for (final recipeMap in results) {
      final recipe = await getRecipe(recipeMap['id'] as int);
      if (recipe != null) {
        recipes.add(recipe);
      }
    }
    return recipes;
  }

  Future<List<Recipe>> getRecipesByIngredients(List<int> ingredientIds) async {
    if (ingredientIds.isEmpty) return [];

    final db = await database;
    final placeholders = List.filled(ingredientIds.length, '?').join(',');

    final results = await db.rawQuery('''
      SELECT DISTINCT r.*
      FROM recipes r
      JOIN recipe_ingredients ri ON r.id = ri.recipeId
      WHERE ri.ingredientId IN ($placeholders)
      ORDER BY r.title ASC
    ''', ingredientIds);

    final recipes = <Recipe>[];
    for (final recipeMap in results) {
      final recipe = await getRecipe(recipeMap['id'] as int);
      if (recipe != null) {
        recipes.add(recipe);
      }
    }
    return recipes;
  }

  Future<int> updateRecipe(Recipe recipe) async {
    if (recipe.id == null) throw ArgumentError('Recipe ID cannot be null for update');

    final db = await database;

    // Update recipe
    await db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );

    // Delete old ingredients and steps
    await db.delete('recipe_ingredients', where: 'recipeId = ?', whereArgs: [recipe.id]);
    await db.delete('recipe_steps', where: 'recipeId = ?', whereArgs: [recipe.id]);

    // Insert new ingredients
    for (final ingredient in recipe.ingredients) {
      await db.insert('recipe_ingredients', {
        'recipeId': recipe.id,
        'ingredientId': ingredient.ingredientId,
        'amount': ingredient.amount,
        'unitId': ingredient.unitId,
      });
    }

    // Insert new steps
    for (int i = 0; i < recipe.instructions.length; i++) {
      await db.insert('recipe_steps', {
        'recipeId': recipe.id,
        'stepNumber': i + 1,
        'instruction': recipe.instructions[i],
      });
    }

    return recipe.id!;
  }

  Future<int> toggleFavorite(int recipeId) async {
    final db = await database;
    final recipe = await getRecipe(recipeId);
    if (recipe == null) return 0;

    return await db.update(
      'recipes',
      {'isFavorite': recipe.isFavorite ? 0 : 1},
      where: 'id = ?',
      whereArgs: [recipeId],
    );
  }

  Future<int> deleteRecipe(int id) async {
    final db = await database;
    return await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== FOOD ITEM INGREDIENT TAGGING =====

  Future<void> tagFoodItemWithIngredient(String foodItemId, int ingredientId) async {
    final db = await database;
    await db.insert(
      'food_item_ingredients',
      {'foodItemId': foodItemId, 'ingredientId': ingredientId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> untagFoodItemIngredient(String foodItemId, int ingredientId) async {
    final db = await database;
    await db.delete(
      'food_item_ingredients',
      where: 'foodItemId = ? AND ingredientId = ?',
      whereArgs: [foodItemId, ingredientId],
    );
  }

  Future<List<Ingredient>> getFoodItemIngredients(String foodItemId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT i.*
      FROM ingredients i
      JOIN food_item_ingredients fii ON i.id = fii.ingredientId
      WHERE fii.foodItemId = ?
      ORDER BY i.name ASC
    ''', [foodItemId]);

    return results.map((map) => Ingredient.fromMap(map)).toList();
  }

  Future<List<Recipe>> getRecipesForFoodItem(String foodItemId) async {
    final db = await database;

    // Get ingredient IDs for this food item
    final ingredientResults = await db.query(
      'food_item_ingredients',
      columns: ['ingredientId'],
      where: 'foodItemId = ?',
      whereArgs: [foodItemId],
    );

    if (ingredientResults.isEmpty) return [];

    final ingredientIds = ingredientResults
        .map((map) => map['ingredientId'] as int)
        .toList();

    return await getRecipesByIngredients(ingredientIds);
  }

  // ===== FOOD ITEM OPERATIONS =====

  Future<String> createOrUpdateFoodItem(FoodItem item) async {
    final db = await database;

    // Insert or replace food item
    await db.insert(
      'food_items',
      {
        'id': item.id,
        'name': item.name,
        'weightPerItemGrams': item.weightPerItemGrams,
        'kcalPerHundredGrams': item.kcalPerHundredGrams,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update ingredient tags
    await db.delete('food_item_ingredients', where: 'foodItemId = ?', whereArgs: [item.id]);
    for (final ingredientId in item.ingredientIds) {
      await db.insert(
        'food_item_ingredients',
        {'foodItemId': item.id, 'ingredientId': ingredientId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    return item.id;
  }

  Future<FoodItem?> getFoodItem(String id) async {
    final db = await database;
    final results = await db.query(
      'food_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final map = results.first;

    // Get ingredient IDs
    final ingredientResults = await db.query(
      'food_item_ingredients',
      columns: ['ingredientId'],
      where: 'foodItemId = ?',
      whereArgs: [id],
    );
    final ingredientIds = ingredientResults
        .map((map) => map['ingredientId'] as int)
        .toList();

    return FoodItem(
      id: map['id'] as String,
      name: map['name'] as String,
      weightPerItemGrams: map['weightPerItemGrams'] as double,
      kcalPerHundredGrams: map['kcalPerHundredGrams'] as double,
      ingredientIds: ingredientIds,
    );
  }

  Future<List<FoodItem>> getAllFoodItems() async {
    final db = await database;
    final results = await db.query('food_items', orderBy: 'name ASC');

    final foodItems = <FoodItem>[];
    for (final map in results) {
      final item = await getFoodItem(map['id'] as String);
      if (item != null) {
        foodItems.add(item);
      }
    }
    return foodItems;
  }

  Future<int> deleteFoodItem(String id) async {
    final db = await database;
    return await db.delete(
      'food_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== INVENTORY BATCH OPERATIONS =====

  Future<String> createInventoryBatch(InventoryBatch batch) async {
    final db = await database;

    // First ensure the food item exists
    await createOrUpdateFoodItem(batch.item);

    // Insert the batch
    await db.insert(
      'inventory_batches',
      {
        'id': batch.id,
        'foodItemId': batch.item.id,
        'count': batch.count,
        'initialCount': batch.initialCount,
        'expirationDate': batch.expirationDate.toIso8601String(),
        'dateAdded': batch.dateAdded.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return batch.id;
  }

  Future<InventoryBatch?> getInventoryBatch(String id) async {
    final db = await database;
    final results = await db.query(
      'inventory_batches',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final map = results.first;
    final foodItem = await getFoodItem(map['foodItemId'] as String);
    if (foodItem == null) return null;

    return InventoryBatch(
      id: map['id'] as String,
      item: foodItem,
      count: map['count'] as int,
      initialCount: map['initialCount'] as int,
      expirationDate: DateTime.parse(map['expirationDate'] as String),
      dateAdded: DateTime.parse(map['dateAdded'] as String),
    );
  }

  Future<List<InventoryBatch>> getAllInventoryBatches() async {
    final db = await database;
    final results = await db.query(
      'inventory_batches',
      orderBy: 'expirationDate ASC',
    );

    final batches = <InventoryBatch>[];
    for (final map in results) {
      final batch = await getInventoryBatch(map['id'] as String);
      if (batch != null) {
        batches.add(batch);
      }
    }
    return batches;
  }

  Future<int> updateInventoryBatch(InventoryBatch batch) async {
    final db = await database;

    // Update the food item if needed
    await createOrUpdateFoodItem(batch.item);

    // Update the batch
    return await db.update(
      'inventory_batches',
      {
        'foodItemId': batch.item.id,
        'count': batch.count,
        'initialCount': batch.initialCount,
        'expirationDate': batch.expirationDate.toIso8601String(),
        'dateAdded': batch.dateAdded.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }

  Future<int> deleteInventoryBatch(String id) async {
    final db = await database;
    return await db.delete(
      'inventory_batches',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== CONSUMPTION QUOTA OPERATIONS =====

  /// Create a new consumption quota
  Future<String> createConsumptionQuota(ConsumptionQuota quota) async {
    final db = await database;

    await db.insert(
      'consumption_quotas',
      quota.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return quota.id;
  }

  /// Create multiple consumption quotas at once
  Future<void> createConsumptionQuotas(List<ConsumptionQuota> quotas) async {
    final db = await database;
    final batch = db.batch();

    for (final quota in quotas) {
      batch.insert(
        'consumption_quotas',
        quota.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get a single consumption quota by ID
  Future<ConsumptionQuota?> getConsumptionQuota(String id) async {
    final db = await database;
    final results = await db.query(
      'consumption_quotas',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return ConsumptionQuota.fromJson(results.first);
  }

  /// Get all consumption quotas
  Future<List<ConsumptionQuota>> getAllConsumptionQuotas() async {
    final db = await database;
    final results = await db.query(
      'consumption_quotas',
      orderBy: 'targetDate ASC',
    );

    return results.map((map) => ConsumptionQuota.fromJson(map)).toList();
  }

  /// Get consumption quotas for a specific batch
  Future<List<ConsumptionQuota>> getConsumptionQuotasForBatch(String batchId) async {
    final db = await database;
    final results = await db.query(
      'consumption_quotas',
      where: 'batchId = ?',
      whereArgs: [batchId],
      orderBy: 'targetDate ASC',
    );

    return results.map((map) => ConsumptionQuota.fromJson(map)).toList();
  }

  /// Get consumption quotas for a specific food item
  Future<List<ConsumptionQuota>> getConsumptionQuotasForFoodItem(String foodItemId) async {
    final db = await database;
    final results = await db.query(
      'consumption_quotas',
      where: 'foodItemId = ?',
      whereArgs: [foodItemId],
      orderBy: 'targetDate ASC',
    );

    return results.map((map) => ConsumptionQuota.fromJson(map)).toList();
  }

  /// Get consumption quotas within a date range
  Future<List<ConsumptionQuota>> getConsumptionQuotasByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final results = await db.query(
      'consumption_quotas',
      where: 'targetDate >= ? AND targetDate <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'targetDate ASC',
    );

    return results.map((map) => ConsumptionQuota.fromJson(map)).toList();
  }

  /// Get active (incomplete) consumption quotas
  Future<List<ConsumptionQuota>> getActiveConsumptionQuotas() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT * FROM consumption_quotas
      WHERE consumedCount < targetCount
      ORDER BY targetDate ASC
    ''');

    return results.map((map) => ConsumptionQuota.fromJson(map)).toList();
  }

  /// Get overdue consumption quotas
  Future<List<ConsumptionQuota>> getOverdueConsumptionQuotas() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final results = await db.rawQuery('''
      SELECT * FROM consumption_quotas
      WHERE targetDate < ? AND consumedCount < targetCount
      ORDER BY targetDate ASC
    ''', [now]);

    return results.map((map) => ConsumptionQuota.fromJson(map)).toList();
  }

  /// Update a consumption quota
  Future<int> updateConsumptionQuota(ConsumptionQuota quota) async {
    final db = await database;

    return await db.update(
      'consumption_quotas',
      quota.toJson(),
      where: 'id = ?',
      whereArgs: [quota.id],
    );
  }

  /// Update multiple consumption quotas at once
  Future<void> updateConsumptionQuotas(List<ConsumptionQuota> quotas) async {
    final db = await database;
    final batch = db.batch();

    for (final quota in quotas) {
      batch.update(
        'consumption_quotas',
        quota.toJson(),
        where: 'id = ?',
        whereArgs: [quota.id],
      );
    }

    await batch.commit(noResult: true);
  }

  /// Delete a consumption quota
  Future<int> deleteConsumptionQuota(String id) async {
    final db = await database;
    return await db.delete(
      'consumption_quotas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all consumption quotas for a specific batch
  Future<int> deleteConsumptionQuotasForBatch(String batchId) async {
    final db = await database;
    return await db.delete(
      'consumption_quotas',
      where: 'batchId = ?',
      whereArgs: [batchId],
    );
  }

  /// Delete all consumption quotas for a specific food item
  Future<int> deleteConsumptionQuotasForFoodItem(String foodItemId) async {
    final db = await database;
    return await db.delete(
      'consumption_quotas',
      where: 'foodItemId = ?',
      whereArgs: [foodItemId],
    );
  }

  // ===== DATABASE MANAGEMENT =====

  /// Clear all recipes and related data (ingredients references, steps)
  /// This will delete all recipes but preserve ingredients and units
  Future<void> clearAllRecipes() async {
    final db = await database;
    await db.delete('recipe_steps');
    await db.delete('recipe_ingredients');
    await db.delete('recipes');
  }

  /// Clear all inventory data (batches and quotas)
  /// This will preserve food items but delete all batches and quotas
  Future<void> clearAllInventory() async {
    final db = await database;
    await db.delete('consumption_quotas');
    await db.delete('inventory_batches');
  }

  /// Clear all consumption quotas only
  Future<void> clearAllQuotas() async {
    final db = await database;
    await db.delete('consumption_quotas');
  }

  /// Clear all food items and their inventory
  /// This will cascade delete inventory batches and quotas
  Future<void> clearAllFoodItems() async {
    final db = await database;
    // These will cascade due to foreign key constraints
    await db.delete('food_items');
  }

  /// Clear ALL data from the database (complete reset)
  /// This deletes everything: recipes, ingredients, units, food items, inventory, quotas
  Future<void> clearAllData() async {
    final db = await database;
    // Delete in order to respect foreign key constraints
    await db.delete('recipe_steps');
    await db.delete('recipe_ingredients');
    await db.delete('recipes');
    await db.delete('consumption_quotas');
    await db.delete('inventory_batches');
    await db.delete('food_item_ingredients');
    await db.delete('food_items');
    await db.delete('ingredients');
    await db.delete('units');

    // Re-insert common units
    await _insertCommonUnits(db);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'recipes.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
