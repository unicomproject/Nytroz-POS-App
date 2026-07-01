import '../entities/till.dart';
import '../entities/till_list_query.dart';

abstract class TillRepository {
  Future<TillListResult> getTills({required TillListQuery query});

  Future<Till> createTill(CreateTillInput input);

  Future<List<TillOutletOption>> getOutletOptions();
}
