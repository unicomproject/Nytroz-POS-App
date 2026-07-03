import '../../domain/entities/till.dart';
import '../../domain/repositories/till_repository.dart';
import '../datasources/till_remote_datasource.dart';
import '../mappers/till_mapper.dart';
import '../models/create_till_request_dto.dart';

class TillRepositoryImpl implements TillRepository {
  const TillRepositoryImpl(this._remoteDatasource);

  final TillRemoteDatasource _remoteDatasource;

  @override
  Future<TillListResult> getTills({required TillListQuery query}) async {
    final dto = await _remoteDatasource.getTills(query);
    return TillMapper.toListResult(dto);
  }

  @override
  Future<CreatedTill> createTill(TillFormData form) async {
    final dto = await _remoteDatasource.createTill(
      CreateTillRequestDto(
        name: form.name,
        code: form.code,
        outletId: form.outletId,
        status: form.status,
      ),
    );

    return TillMapper.toCreatedEntity(dto);
  }
}
