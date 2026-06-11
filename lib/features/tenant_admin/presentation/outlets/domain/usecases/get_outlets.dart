import '../entities/outlet.dart';
import '../repositories/outlet_repository.dart';

class GetOutlets {
  const GetOutlets(this._repository);

  final OutletRepository _repository;

  Future<OutletListResult> call({String? search}) {
    return _repository.getOutlets(search: search);
  }
}
