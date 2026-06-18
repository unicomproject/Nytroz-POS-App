import '../../domain/repositories/outlet_repository.dart';

class DeleteOutlet {
  const DeleteOutlet(this._repository);

  final OutletRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteOutlet(id);
  }
}
