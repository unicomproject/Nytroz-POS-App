import '../../domain/entities/till.dart';
import '../../domain/repositories/till_repository.dart';

class GetTillById {
  const GetTillById(this._repository);

  final TillRepository _repository;

  Future<TillDetail> call(String id) {
    return _repository.getTillById(id);
  }
}
