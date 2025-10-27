import 'package:inventory_manager/models/consumption_period.dart';
import 'package:inventory_manager/models/inventory_batch.dart';

abstract class ConsumptionQuotaEvent {
  const ConsumptionQuotaEvent();
}

/// Load all consumption quotas
class LoadConsumptionQuotas extends ConsumptionQuotaEvent {
  const LoadConsumptionQuotas();
}

/// Load quotas for the current period
class LoadCurrentPeriodQuotas extends ConsumptionQuotaEvent {
  const LoadCurrentPeriodQuotas();
}

/// Load quotas for upcoming periods
class LoadUpcomingQuotas extends ConsumptionQuotaEvent {
  final int numberOfPeriods;

  const LoadUpcomingQuotas({this.numberOfPeriods = 1});
}

/// Generate quotas for a new batch
class GenerateQuotasForBatch extends ConsumptionQuotaEvent {
  final InventoryBatch batch;

  const GenerateQuotasForBatch(this.batch);
}

/// Complete/increment a quota (mark items as consumed)
class CompleteQuota extends ConsumptionQuotaEvent {
  final String quotaId;
  final int itemCount;

  const CompleteQuota({
    required this.quotaId,
    required this.itemCount,
  });
}

/// Change the user's preferred period
class ChangePreferredPeriod extends ConsumptionQuotaEvent {
  final ConsumptionPeriod newPeriod;

  const ChangePreferredPeriod(this.newPeriod);
}

/// Regenerate all quotas with a new period
class RegenerateAllQuotas extends ConsumptionQuotaEvent {
  final ConsumptionPeriod newPeriod;

  const RegenerateAllQuotas(this.newPeriod);
}

/// Delete quotas for a specific batch
class DeleteQuotasForBatch extends ConsumptionQuotaEvent {
  final String batchId;

  const DeleteQuotasForBatch(this.batchId);
}

/// Refresh quotas (reload from database)
class RefreshQuotas extends ConsumptionQuotaEvent {
  const RefreshQuotas();
}

/// Clear all quotas and regenerate from current batches
class ClearAndRegenerateAllQuotas extends ConsumptionQuotaEvent {
  const ClearAndRegenerateAllQuotas();
}
