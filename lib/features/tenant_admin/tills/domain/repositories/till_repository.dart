import '../entities/till.dart';

abstract class TillRepository {
  Future<TillListResult> getTills({required TillListQuery query});

  Future<CreatedTill> createTill(TillFormData form);
}
