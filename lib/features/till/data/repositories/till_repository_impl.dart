import '../../domain/entities/open_till.dart';
import '../../domain/repositories/till_repository.dart';
import '../datasources/till_remote_datasource.dart';

class TillRepositoryImpl implements TillRepository {
  const TillRepositoryImpl(this._datasource);

  final TillRemoteDatasource _datasource;

  @override
  Future<TillSession> openTill(OpenTillForm form) {
    return _datasource.openTill(form);
  }
}
