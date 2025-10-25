import 'package:inventory_manager/models/consumption_quota.dart';
import 'package:inventory_manager/models/consumption_period.dart';

abstract class ConsumptionQuotaState {
  const ConsumptionQuotaState();
}

/// Initial state before any data is loaded
class ConsumptionQuotaInitial extends ConsumptionQuotaState {
  const ConsumptionQuotaInitial();
}

/// Loading state
class ConsumptionQuotaLoading extends ConsumptionQuotaState {
  const ConsumptionQuotaLoading();
}

/// Loaded state with quotas grouped by food item
class ConsumptionQuotaLoaded extends ConsumptionQuotaState {
  final Map<String, List<ConsumptionQuota>> quotasByFoodItem;
  final ConsumptionPeriod selectedPeriod;
  final DateTime lastUpdated;

  const ConsumptionQuotaLoaded({
    required this.quotasByFoodItem,
    required this.selectedPeriod,
    required this.lastUpdated,
  });

  /// Get all quotas as a flat list
  List<ConsumptionQuota> get allQuotas {
    return quotasByFoodItem.values.expand((quotas) => quotas).toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
  }

  /// Get active (incomplete) quotas
  List<ConsumptionQuota> get activeQuotas {
    return allQuotas.where((q) => !q.isCompleted).toList();
  }

  /// Get completed quotas
  List<ConsumptionQuota> get completedQuotas {
    return allQuotas.where((q) => q.isCompleted).toList();
  }

  /// Get overdue quotas
  List<ConsumptionQuota> get overdueQuotas {
    return allQuotas.where((q) => q.isOverdue).toList();
  }

  /// Get quotas due soon
  List<ConsumptionQuota> get dueSoonQuotas {
    return allQuotas.where((q) => q.isDueSoon).toList();
  }

  /// Get total progress percentage across all quotas
  double get overallProgress {
    if (allQuotas.isEmpty) return 0.0;

    final totalTarget = allQuotas.fold<int>(0, (sum, q) => sum + q.targetCount);
    final totalConsumed = allQuotas.fold<int>(0, (sum, q) => sum + q.consumedCount);

    if (totalTarget == 0) return 0.0;
    return (totalConsumed / totalTarget * 100).clamp(0.0, 100.0);
  }

  /// Get number of food items being tracked
  int get trackedFoodItemCount => quotasByFoodItem.length;

  ConsumptionQuotaLoaded copyWith({
    Map<String, List<ConsumptionQuota>>? quotasByFoodItem,
    ConsumptionPeriod? selectedPeriod,
    DateTime? lastUpdated,
  }) {
    return ConsumptionQuotaLoaded(
      quotasByFoodItem: quotasByFoodItem ?? this.quotasByFoodItem,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Error state
class ConsumptionQuotaError extends ConsumptionQuotaState {
  final String message;

  const ConsumptionQuotaError(this.message);
}
