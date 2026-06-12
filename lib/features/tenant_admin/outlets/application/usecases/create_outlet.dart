import '../../domain/entities/outlet_details.dart';
import '../../domain/repositories/outlet_repository.dart';

class CreateOutlet {
  const CreateOutlet(this._repository);

  final OutletRepository _repository;

  Future<OutletDetails> call(OutletFormData form) {
    return _repository.createOutlet(form);
  }
}
