import 'package:inventory_manager/services/recipe_database.dart';
import 'package:inventory_manager/services/notification_service.dart';

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

    // Initialize notifications
    await _initializeNotifications();
  }

  /// Initialize the notification service
  static Future<void> _initializeNotifications() async {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      // Request permissions immediately on startup
      await notificationService.requestPermissions();
    } catch (e) {
      // Notification initialization failure shouldn't block app launch
      // Log error if you have logging set up
    }
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
