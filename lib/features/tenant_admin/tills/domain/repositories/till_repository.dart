import '../entities/till.dart';
import '../entities/till_monitoring.dart';
import '../entities/till_hardware_readiness.dart';
import '../entities/till_create_options.dart';

abstract class TillRepository {
  Future<TillMonitoringResult> getTills({required TillListQuery query});
  Future<TillMonitoringSummary> getTillSummary();
  Future<TillHardwareReadiness> getTillHardwareReadiness(String id);

  Future<TillDetail> getTillById(String id);

  Future<CreatedTill> createTill(TillFormData form);

  Future<CreatedTill> createTillSetup(AddTillFormData form);

  Future<TillDetail> updateTill(String id, TillFormData form);

  Future<void> deleteTill(String id);

  Future<List<OutletOption>> getOutletOptions();

  Future<TillCreateOptions> getCreateOptions({String? outletId});
}
