import '../../domain/repositories/outlet_repository.dart';

class UpdateOutletStatus {
  const UpdateOutletStatus(this._repository);

  final OutletRepository _repository;

  Future<void> call(String id, String status) =>
      _repository.updateOutletStatus(id, status);
}
