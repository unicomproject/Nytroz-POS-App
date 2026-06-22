import '../../../outlets/data/datasources/outlet_remote_datasource.dart';
import '../../../outlets/domain/entities/outlet_list_query.dart';
import '../../domain/entities/till.dart';
import '../../domain/entities/till_list_query.dart';
import '../../domain/repositories/till_repository.dart';
import '../datasources/till_remote_datasource.dart';
import '../mappers/till_mapper.dart';

class TillRepositoryImpl implements TillRepository {
  const TillRepositoryImpl(this._remoteDatasource, this._outletRemoteDatasource);

  final TillRemoteDatasource _remoteDatasource;
  final OutletRemoteDatasource _outletRemoteDatasource;

  @override
  Future<TillListResult> getTills({required TillListQuery query}) async {
    final dto = await _remoteDatasource.getTills(query);
    return TillMapper.toListResult(dto);
  }

  @override
  Future<Till> createTill(CreateTillInput input) async {
    final dto = await _remoteDatasource.createTill(
      TillMapper.toCreateRequest(input),
    );
    return TillMapper.toEntity(dto);
  }

  @override
  Future<List<TillOutletOption>> getOutletOptions() async {
    final result = await _outletRemoteDatasource.getOutlets(
      const OutletListQuery(page: 1, pageSize: 100),
    );

    return result.items
        .map(
          (outlet) => TillOutletOption(
            id: outlet.id,
            name: outlet.name,
            code: outlet.code,
          ),
        )
        .toList(growable: false);
  }
}
