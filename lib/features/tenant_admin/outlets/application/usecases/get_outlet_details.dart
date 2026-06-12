import '../../domain/entities/outlet_details.dart';
import '../../domain/repositories/outlet_repository.dart';

class GetOutletDetails {
  const GetOutletDetails(this._repository);

  final OutletRepository _repository;

  Future<OutletDetails> call(String id) {
    return _repository.getOutletDetails(id);
  }
}
