import 'package:inventory_manager/services/recipe_database.dart';

/// Service to handle app initialization tasks
class AppInitialization {
  /// Initialize the app on first launch or startup
  ///
  /// This should be called in your main.dart before running the app
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await AppInitialization.initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> initialize() async {
    // Initialize the database
    await _initializeDatabase();
  }

  /// Initialize the recipe database
  static Future<void> _initializeDatabase() async {
    try {
      // Access the database to trigger creation if it doesn't exist
      final db = RecipeDatabase.instance;
      await db.database;
    } catch (e) {
      // You might want to show an error dialog to the user here
      rethrow;
    }
  }
}
