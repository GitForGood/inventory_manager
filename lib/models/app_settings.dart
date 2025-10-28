import 'package:inventory_manager/models/consumption_period.dart';

class AppSettings {
  final bool notificationsEnabled;
  final bool expirationNotificationsEnabled;
  final bool quotaGenerationNotificationsEnabled;
  final bool highContrast;
  final int expirationWarningDays;
  final ConsumptionPeriod preferredQuotaInterval;
  final int? inventoryCalorieTarget; // Target calories for total inventory

  const AppSettings({
    this.notificationsEnabled = true,
    this.expirationNotificationsEnabled = true,
    this.quotaGenerationNotificationsEnabled = true,
    this.highContrast = false,
    this.expirationWarningDays = 7,
    this.preferredQuotaInterval = ConsumptionPeriod.weekly,
    this.inventoryCalorieTarget,
  });

  // CopyWith method for immutable updates
  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? expirationNotificationsEnabled,
    bool? quotaGenerationNotificationsEnabled,
    bool? highContrast,
    int? expirationWarningDays,
    ConsumptionPeriod? preferredQuotaInterval,
    int? inventoryCalorieTarget,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      expirationNotificationsEnabled: expirationNotificationsEnabled ?? this.expirationNotificationsEnabled,
      quotaGenerationNotificationsEnabled: quotaGenerationNotificationsEnabled ?? this.quotaGenerationNotificationsEnabled,
      highContrast: highContrast ?? this.highContrast,
      expirationWarningDays: expirationWarningDays ?? this.expirationWarningDays,
      preferredQuotaInterval: preferredQuotaInterval ?? this.preferredQuotaInterval,
      inventoryCalorieTarget: inventoryCalorieTarget ?? this.inventoryCalorieTarget,
    );
  }

  // Equality operator for comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.notificationsEnabled == notificationsEnabled &&
        other.expirationNotificationsEnabled == expirationNotificationsEnabled &&
        other.quotaGenerationNotificationsEnabled == quotaGenerationNotificationsEnabled &&
        other.highContrast == highContrast &&
        other.expirationWarningDays == expirationWarningDays &&
        other.preferredQuotaInterval == preferredQuotaInterval &&
        other.inventoryCalorieTarget == inventoryCalorieTarget;
  }

  // HashCode for collections and comparisons
  @override
  int get hashCode {
    return Object.hash(
      notificationsEnabled,
      expirationNotificationsEnabled,
      quotaGenerationNotificationsEnabled,
      highContrast,
      expirationWarningDays,
      preferredQuotaInterval,
      inventoryCalorieTarget,
    );
  }

  // ToString for debugging
  @override
  String toString() {
    return 'AppSettings('
           'notifications: $notificationsEnabled, '
           'expirationNotifications: $expirationNotificationsEnabled, '
           'quotaGenerationNotifications: $quotaGenerationNotificationsEnabled, '
           'highContrast: $highContrast, '
           'warningDays: $expirationWarningDays, '
           'quotaInterval: $preferredQuotaInterval)';
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'expirationNotificationsEnabled': expirationNotificationsEnabled,
      'quotaGenerationNotificationsEnabled': quotaGenerationNotificationsEnabled,
      'highContrast': highContrast,
      'expirationWarningDays': expirationWarningDays,
      'preferredQuotaInterval': preferredQuotaInterval.index,
    };
  }

  // Create from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      expirationNotificationsEnabled: json['expirationNotificationsEnabled'] as bool? ?? true,
      quotaGenerationNotificationsEnabled: json['quotaGenerationNotificationsEnabled'] as bool? ?? true,
      highContrast: json['highContrast'] as bool? ?? false,
      expirationWarningDays: json['expirationWarningDays'] as int? ?? 7,
      preferredQuotaInterval: ConsumptionPeriod.values[json['preferredQuotaInterval'] as int? ?? ConsumptionPeriod.weekly.index],
    );
  }
}
