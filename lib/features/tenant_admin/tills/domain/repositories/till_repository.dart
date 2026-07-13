import '../entities/till.dart';

abstract class TillRepository {
  Future<TillListResult> getTills({required TillListQuery query});

  Future<TillDetail> getTillById(String id);

  Future<CreatedTill> createTill(TillFormData form);

  Future<TillDetail> updateTill(String id, TillFormData form);

  Future<void> deleteTill(String id);

  Future<List<OutletOption>> getOutletOptions();
}
