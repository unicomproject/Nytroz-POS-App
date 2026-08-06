import '../../domain/entities/till.dart';
import '../../domain/entities/till_monitoring.dart';
import '../../domain/repositories/till_repository.dart';

class GetTills {
  const GetTills(this._repository);

  final TillRepository _repository;

  Future<TillMonitoringResult> call({required TillListQuery query}) {
    return _repository.getTills(query: query);
  }
}
