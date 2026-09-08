import '../../domain/repositories/outlet_repository.dart';

class RemoveOutletManager {
  const RemoveOutletManager(this._repository);

  final OutletRepository _repository;

  Future<void> call(String id) => _repository.removeOutletManager(id);
}
