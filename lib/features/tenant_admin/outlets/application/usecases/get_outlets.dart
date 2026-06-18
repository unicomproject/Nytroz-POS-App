import '../../domain/entities/outlet.dart';
import '../../domain/entities/outlet_list_query.dart';
import '../../domain/repositories/outlet_repository.dart';

class GetOutlets {
  const GetOutlets(this._repository);

  final OutletRepository _repository;

  Future<OutletListResult> call({required OutletListQuery query}) {
    return _repository.getOutlets(query: query);
  }
}
