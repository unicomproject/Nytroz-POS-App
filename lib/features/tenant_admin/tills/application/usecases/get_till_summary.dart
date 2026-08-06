import '../../domain/entities/till_monitoring.dart';
import '../../domain/repositories/till_repository.dart';

class GetTillSummary {
  const GetTillSummary(this._repository);

  final TillRepository _repository;

  Future<TillMonitoringSummary> call() {
    return _repository.getTillSummary();
  }
}
