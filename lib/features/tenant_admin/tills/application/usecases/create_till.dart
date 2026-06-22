import '../../domain/entities/till.dart';
import '../../domain/repositories/till_repository.dart';

class CreateTill {
  const CreateTill(this._repository);

  final TillRepository _repository;

  Future<CreatedTill> call(TillFormData form) {
    return _repository.createTill(form);
  }
}
