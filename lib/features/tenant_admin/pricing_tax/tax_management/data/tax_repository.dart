import '../domain/tax_aggregate.dart';
import '../domain/tax_status.dart';

abstract class TaxRepository {
  Future<TaxSetupListResult> listTaxSetups(TaxSetupListQuery query);

  Future<TaxSetup> getTaxSetup(String id);

  Future<String> createTaxSetup(TaxSetupCreateInput input);

  Future<void> updateTaxSetup(String id, TaxSetupUpdateInput input);

  Future<void> scheduleRate(String id, TaxRateScheduleInput input);

  Future<void> updateScheduledRate(
    String id,
    String rateId,
    TaxRateScheduleInput input,
  );

  Future<void> deleteScheduledRate(String id, String rateId);

  Future<TaxStatusChangeResult> activateTaxSetup(String id);

  Future<TaxStatusChangeResult> deactivateTaxSetup(
    String id, {
    String? reason,
  });

  Future<TaxProductUsingListResult> listProductsUsing(
    String id,
    TaxProductsQuery query,
  );
}

extension TaxStatusApi on TaxStatus {
  String get queryValue => apiValue;
}
