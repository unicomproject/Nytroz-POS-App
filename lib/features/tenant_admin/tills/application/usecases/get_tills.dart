import '../../domain/entities/till.dart';
import '../../domain/entities/till_list_query.dart';
import '../../domain/repositories/till_repository.dart';

class GetTills {
  const GetTills(this._repository);

  final TillRepository _repository;

  Future<TillListResult> call({required TillListQuery query}) {
    return _repository.getTills(query: query);
  }
}
