import '../../domain/entities/outlet_details.dart';
import '../../domain/repositories/outlet_repository.dart';

class UpdateOutlet {
  const UpdateOutlet(this._repository);

  final OutletRepository _repository;

  Future<OutletDetails> call(String id, OutletFormData form) {
    return _repository.updateOutlet(id, form);
  }
}
