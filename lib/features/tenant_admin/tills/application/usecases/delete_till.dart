import '../../domain/repositories/till_repository.dart';

class DeleteTill {
  const DeleteTill(this._repository);

  final TillRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteTill(id);
  }
}
