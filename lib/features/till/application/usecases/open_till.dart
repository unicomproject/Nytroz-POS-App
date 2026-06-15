import '../../domain/entities/open_till.dart';
import '../../domain/repositories/till_repository.dart';

class OpenTill {
  const OpenTill(this._repository);

  final TillRepository _repository;

  Future<TillSession> call(OpenTillForm form) {
    return _repository.openTill(form);
  }
}
