import 'package:inventory_manager/models/consumption_period.dart';
import 'package:inventory_manager/models/daily_calorie_target.dart';

class AppSettings {
  final bool notificationsEnabled;
  final bool expirationNotificationsEnabled;
  final bool quotaGenerationNotificationsEnabled;
  final bool highContrast;
  final ConsumptionPeriod preferredQuotaInterval;
  final DailyCalorieTarget? dailyCalorieTarget;

  const AppSettings({
    this.notificationsEnabled = true,
    this.expirationNotificationsEnabled = true,
    this.quotaGenerationNotificationsEnabled = true,
    this.highContrast = false,
    this.preferredQuotaInterval = ConsumptionPeriod.weekly,
    this.dailyCalorieTarget,
  });

  // CopyWith method for immutable updates
  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? expirationNotificationsEnabled,
    bool? quotaGenerationNotificationsEnabled,
    bool? highContrast,
    ConsumptionPeriod? preferredQuotaInterval,
    Object? dailyCalorieTarget = _undefined,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      expirationNotificationsEnabled: expirationNotificationsEnabled ?? this.expirationNotificationsEnabled,
      quotaGenerationNotificationsEnabled: quotaGenerationNotificationsEnabled ?? this.quotaGenerationNotificationsEnabled,
      highContrast: highContrast ?? this.highContrast,
      preferredQuotaInterval: preferredQuotaInterval ?? this.preferredQuotaInterval,
      dailyCalorieTarget: dailyCalorieTarget == _undefined
          ? this.dailyCalorieTarget
          : dailyCalorieTarget as DailyCalorieTarget?,
    );
  }

  static const _undefined = Object();

  // Equality operator for comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.notificationsEnabled == notificationsEnabled &&
        other.expirationNotificationsEnabled == expirationNotificationsEnabled &&
        other.quotaGenerationNotificationsEnabled == quotaGenerationNotificationsEnabled &&
        other.highContrast == highContrast &&
        other.preferredQuotaInterval == preferredQuotaInterval &&
        _calorieTargetsEqual(other.dailyCalorieTarget, dailyCalorieTarget);
  }

  // Helper to compare calorie targets
  bool _calorieTargetsEqual(DailyCalorieTarget? a, DailyCalorieTarget? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.runtimeType != b.runtimeType) return false;

    if (a is ManualCalorieTarget && b is ManualCalorieTarget) {
      return a.target == b.target;
    } else if (a is CalculatedCalorieTarget && b is CalculatedCalorieTarget) {
      return a.people == b.people &&
             a.days == b.days &&
             a.caloriesPerPerson == b.caloriesPerPerson;
    }
    return false;
  }

  // HashCode for collections and comparisons
  @override
  int get hashCode {
    return Object.hash(
      notificationsEnabled,
      expirationNotificationsEnabled,
      quotaGenerationNotificationsEnabled,
      highContrast,
      preferredQuotaInterval,
      dailyCalorieTarget?.target,
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
           'quotaInterval: $preferredQuotaInterval, ';
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    Map<String, dynamic>? calorieTargetJson;
    if (dailyCalorieTarget != null) {
      if (dailyCalorieTarget is ManualCalorieTarget) {
        final manual = dailyCalorieTarget as ManualCalorieTarget;
        calorieTargetJson = {
          'type': 'manual',
          'target': manual.target,
        };
      } else if (dailyCalorieTarget is CalculatedCalorieTarget) {
        final calculated = dailyCalorieTarget as CalculatedCalorieTarget;
        calorieTargetJson = {
          'type': 'calculated',
          'people': calculated.people,
          'days': calculated.days,
          'caloriesPerPerson': calculated.caloriesPerPerson,
        };
      }
    }

    return {
      'notificationsEnabled': notificationsEnabled,
      'expirationNotificationsEnabled': expirationNotificationsEnabled,
      'quotaGenerationNotificationsEnabled': quotaGenerationNotificationsEnabled,
      'highContrast': highContrast,
      'preferredQuotaInterval': preferredQuotaInterval.index,
      if (calorieTargetJson != null) 'dailyCalorieTarget': calorieTargetJson,
    };
  }

  // Create from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    DailyCalorieTarget? dailyCalorieTarget;
    final calorieTargetJson = json['dailyCalorieTarget'] as Map<String, dynamic>?;
    if (calorieTargetJson != null) {
      final type = calorieTargetJson['type'] as String?;
      if (type == 'manual') {
        dailyCalorieTarget = ManualCalorieTarget(
          target: calorieTargetJson['target'] as int,
        );
      } else if (type == 'calculated') {
        dailyCalorieTarget = CalculatedCalorieTarget(
          people: calorieTargetJson['people'] as int,
          days: calorieTargetJson['days'] as int,
          caloriesPerPerson: calorieTargetJson['caloriesPerPerson'] as int,
        );
      }
    }

    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      expirationNotificationsEnabled: json['expirationNotificationsEnabled'] as bool? ?? true,
      quotaGenerationNotificationsEnabled: json['quotaGenerationNotificationsEnabled'] as bool? ?? true,
      highContrast: json['highContrast'] as bool? ?? false,
      preferredQuotaInterval: ConsumptionPeriod.values[json['preferredQuotaInterval'] as int? ?? ConsumptionPeriod.weekly.index],
      dailyCalorieTarget: dailyCalorieTarget,
    );
  }
}
