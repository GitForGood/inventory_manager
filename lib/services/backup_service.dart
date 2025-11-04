import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inventory_manager/services/recipe_database.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  final RecipeDatabase _db = RecipeDatabase.instance;

  /// Export all data to a compressed JSON file
  Future<BackupResult> exportData() async {
    try {
      // Collect all data from the database
      final database = await _db.database;

      final Map<String, dynamic> backupData = {
        'version': 1,
        'exportDate': DateTime.now().toIso8601String(),
        'recipes': await _exportRecipes(database),
        'ingredients': await _exportIngredients(database),
        'units': await _exportUnits(database),
        'recipeIngredients': await _exportRecipeIngredients(database),
        'recipeSteps': await _exportRecipeSteps(database),
        'foodItems': await _exportFoodItems(database),
        'foodItemIngredients': await _exportFoodItemIngredients(database),
        'inventoryBatches': await _exportInventoryBatches(database),
        'consumptionQuotas': await _exportConsumptionQuotas(database),
      };

      // Convert to JSON
      final jsonString = jsonEncode(backupData);

      // Compress using gzip
      final bytes = utf8.encode(jsonString);
      final compressedList = gzip.encode(bytes);
      final Uint8List compressed = Uint8List.fromList(compressedList);

      // Get the directory to save the file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'inventory_backup_$timestamp.gz';
      final filePath = '${directory.path}/$fileName';

      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(compressed);

      // Let the user choose where to save it
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: fileName,
        bytes: compressed,
        type: FileType.custom,
        allowedExtensions: ['gz'],
      );

      if (result != null) {
        return BackupResult(
          success: true,
          message: 'Backup exported successfully!',
          filePath: result,
        );
      } else {
        // User cancelled, but we still saved to app directory
        return BackupResult(
          success: true,
          message: 'Backup saved to app directory: $filePath',
          filePath: filePath,
        );
      }
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to export backup: $e',
      );
    }
  }

  /// Import data from a compressed JSON backup file
  Future<BackupResult> importData() async {
    try {
      // Let user pick a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gz'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return BackupResult(
          success: false,
          message: 'No file selected',
        );
      }

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        // Try reading from path
        final path = result.files.first.path;
        if (path == null) {
          return BackupResult(
            success: false,
            message: 'Could not read file',
          );
        }
        final file = File(path);
        final compressed = await file.readAsBytes();
        return await _processImportData(compressed);
      }

      return await _processImportData(fileBytes);
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to import backup: $e',
      );
    }
  }

  Future<BackupResult> _processImportData(List<int> compressed) async {
    try {
      // Decompress
      final decompressed = gzip.decode(compressed);
      final jsonString = utf8.decode(decompressed);

      // Parse JSON
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      // Verify version
      final version = backupData['version'] as int;
      if (version != 1) {
        return BackupResult(
          success: false,
          message: 'Unsupported backup version: $version',
        );
      }

      // Import all data
      final database = await _db.database;

      int importedCount = 0;

      await database.transaction((txn) async {
        // Import in the correct order to respect foreign key constraints

        // 1. Import units
        final units = backupData['units'] as List<dynamic>;
        for (final unit in units) {
          await txn.insert('units', unit, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        importedCount += units.length;

        // 2. Import ingredients
        final ingredients = backupData['ingredients'] as List<dynamic>;
        for (final ingredient in ingredients) {
          await txn.insert('ingredients', ingredient, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        importedCount += ingredients.length;

        // 3. Import recipes
        final recipes = backupData['recipes'] as List<dynamic>;
        for (final recipe in recipes) {
          await txn.insert('recipes', recipe, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        importedCount += recipes.length;

        // 4. Import recipe ingredients
        final recipeIngredients = backupData['recipeIngredients'] as List<dynamic>;
        for (final ri in recipeIngredients) {
          await txn.insert('recipe_ingredients', ri, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        importedCount += recipeIngredients.length;

        // 5. Import recipe steps
        final recipeSteps = backupData['recipeSteps'] as List<dynamic>;
        for (final step in recipeSteps) {
          await txn.insert('recipe_steps', step, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        importedCount += recipeSteps.length;

        // 6. Import food items
        final foodItems = backupData['foodItems'] as List<dynamic>;
        for (final item in foodItems) {
          await txn.insert('food_items', item, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        importedCount += foodItems.length;

        // 7. Import food item ingredients
        final foodItemIngredients = backupData['foodItemIngredients'] as List<dynamic>;
        for (final fii in foodItemIngredients) {
          await txn.insert('food_item_ingredients', fii, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        importedCount += foodItemIngredients.length;

        // 8. Import inventory batches
        final inventoryBatches = backupData['inventoryBatches'] as List<dynamic>;
        for (final batch in inventoryBatches) {
          await txn.insert('inventory_batches', batch, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        importedCount += inventoryBatches.length;

        // 9. Import consumption quotas
        final consumptionQuotas = backupData['consumptionQuotas'] as List<dynamic>;
        for (final quota in consumptionQuotas) {
          await txn.insert('consumption_quotas', quota, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        importedCount += consumptionQuotas.length;
      });

      return BackupResult(
        success: true,
        message: 'Successfully imported $importedCount items from backup!',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to process backup data: $e',
      );
    }
  }

  // Export helper methods
  Future<List<Map<String, dynamic>>> _exportRecipes(Database db) async {
    return await db.query('recipes');
  }

  Future<List<Map<String, dynamic>>> _exportIngredients(Database db) async {
    return await db.query('ingredients');
  }

  Future<List<Map<String, dynamic>>> _exportUnits(Database db) async {
    return await db.query('units');
  }

  Future<List<Map<String, dynamic>>> _exportRecipeIngredients(Database db) async {
    return await db.query('recipe_ingredients');
  }

  Future<List<Map<String, dynamic>>> _exportRecipeSteps(Database db) async {
    return await db.query('recipe_steps');
  }

  Future<List<Map<String, dynamic>>> _exportFoodItems(Database db) async {
    return await db.query('food_items');
  }

  Future<List<Map<String, dynamic>>> _exportFoodItemIngredients(Database db) async {
    return await db.query('food_item_ingredients');
  }

  Future<List<Map<String, dynamic>>> _exportInventoryBatches(Database db) async {
    return await db.query('inventory_batches');
  }

  Future<List<Map<String, dynamic>>> _exportConsumptionQuotas(Database db) async {
    return await db.query('consumption_quotas');
  }
}

class BackupResult {
  final bool success;
  final String message;
  final String? filePath;

  BackupResult({
    required this.success,
    required this.message,
    this.filePath,
  });
}
