import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for managing local notifications
/// Handles scheduling and displaying notifications for consumption quota regeneration
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Callback for when a notification is tapped
  static void Function()? onNotificationTap;

  /// Initialize the notification service
  /// Must be called before any other notification operations
  Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with settings and handle notification tap
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (response.notificationResponseType ==
            NotificationResponseType.selectedNotification) {
          onNotificationTap?.call();
        }
      },
    );
  }

  /// Request notification permissions (iOS)
  /// Android permissions are requested at install time
  Future<bool> requestPermissions() async {
    if (await _isAndroid()) {
      // Android 13+ requires runtime permission
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestNotificationsPermission() ?? true;
    } else {
      // iOS permissions
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return granted;
    }
  }

  /// Schedule a notification for quota regeneration
  /// [scheduledDate] - The date and time when the notification should appear
  /// [periodName] - The name of the period (e.g., "Weekly", "Monthly")
  Future<void> scheduleQuotaRegenerationNotification({
    required DateTime scheduledDate,
    required String periodName,
  }) async {
    const notificationId = 0; // Use ID 0 for quota regeneration notifications

    // Convert DateTime to TZDateTime
    final tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'quota_regeneration', // channel ID
      'Quota Regeneration', // channel name
      channelDescription: 'Notifications for when consumption quotas are regenerated',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Cancel any existing scheduled notification
    await _notifications.cancel(notificationId);

    // Schedule the new notification
    await _notifications.zonedSchedule(
      notificationId,
      'Consumption Quotas Regenerated',
      'Your $periodName consumption quotas have been updated. Tap to view.',
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel the scheduled quota regeneration notification
  Future<void> cancelQuotaNotification() async {
    await _notifications.cancel(0);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Show an immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'quota_regeneration',
      'Quota Regeneration',
      channelDescription: 'Notifications for when consumption quotas are regenerated',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  /// Check if running on Android
  Future<bool> _isAndroid() async {
    return _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>() !=
        null;
  }
}
