import '../../domain/repositories/outlet_repository.dart';

class SetOutletManager {
  const SetOutletManager(this._repository);

  final OutletRepository _repository;

  Future<void> call(String id, String tenantUserId) =>
      _repository.setOutletManager(id, tenantUserId);
}
