import '../../domain/entities/till_hardware_readiness.dart';
import '../../domain/repositories/till_repository.dart';

class GetTillHardwareReadiness {
  const GetTillHardwareReadiness(this._repository);

  final TillRepository _repository;

  Future<TillHardwareReadiness> call(String id) {
    return _repository.getTillHardwareReadiness(id);
  }
}
