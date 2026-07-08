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
        tillName: form.name,
        tillCode: form.code,
        outletId: form.outletId,
        status: form.status,
        deviceName: form.deviceName,
        printerName: form.printerName,
        scannerName: form.scannerName,
        cashDrawerName: form.cashDrawerName,
        cardReaderName: form.cardReaderName,
        internalNote: form.internalNote,
      ),
    );

    return TillMapper.toCreatedEntity(dto);
  }

  @override
  Future<List<OutletOption>> getOutletOptions() async {
    final options = await _remoteDatasource.getOutletOptions();
    return options
        .map(
          (option) => OutletOption(
            id: option.id,
            name: option.name,
            code: option.code,
            status: option.status,
          ),
        )
        .toList(growable: false);
  }
}
