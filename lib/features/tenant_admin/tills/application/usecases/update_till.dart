import '../../domain/entities/till.dart';
import '../../domain/repositories/till_repository.dart';

class UpdateTill {
  const UpdateTill(this._repository);

  final TillRepository _repository;

  Future<TillDetail> call({
    required String id,
    required TillFormData form,
  }) {
    return _repository.updateTill(id, form);
  }
}
