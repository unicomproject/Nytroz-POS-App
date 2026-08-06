import '../../domain/entities/till.dart';
import '../../domain/entities/till_monitoring.dart';
import '../../domain/entities/till_hardware_readiness.dart';
import '../../domain/entities/till_create_options.dart';
import '../../domain/repositories/till_repository.dart';
import '../datasources/till_remote_datasource.dart';
import '../mappers/till_mapper.dart';
import '../models/create_till_request_dto.dart';
import '../models/create_till_setup_request_dto.dart';

class TillRepositoryImpl implements TillRepository {
  const TillRepositoryImpl(this._remoteDatasource);

  final TillRemoteDatasource _remoteDatasource;

  @override
  Future<TillMonitoringResult> getTills({required TillListQuery query}) async {
    final dto = await _remoteDatasource.getTills(query);
    return TillMapper.toListResult(dto);
  }

  @override
  Future<TillMonitoringSummary> getTillSummary() async {
    final dto = await _remoteDatasource.getTillSummary();
    return TillMapper.toSummaryEntity(dto);
  }

  @override
  Future<TillHardwareReadiness> getTillHardwareReadiness(String id) async {
    final dto = await _remoteDatasource.getTillHardwareReadiness(id);
    return TillMapper.toHardwareReadiness(dto);
  }

  @override
  Future<TillDetail> getTillById(String id) async {
    final dto = await _remoteDatasource.getTillById(id);
    return TillMapper.toDetailEntity(dto);
  }

  @override
  Future<CreatedTill> createTill(TillFormData form) async {
    final dto = await _remoteDatasource.createTill(_toRequestDto(form));
    return TillMapper.toCreatedEntity(dto);
  }

  @override
  Future<CreatedTill> createTillSetup(AddTillFormData form) async {
    final request = CreateTillSetupRequestDto(
      tillName: form.name,
      tillCode: form.code,
      outletId: form.outletId,
      status: form.status,
      defaultCashierTenantUserId: form.defaultCashierTenantUserId,
      defaultOpeningFloatAmount: form.defaultOpeningFloatAmount,
      posDeviceId: form.posDeviceId,
      hardwareAssignments: form.hardwareAssignments
          .map((e) => CreateTillHardwareAssignmentDto(
                hardwareDeviceId: e.hardwareDeviceId,
                isPrimary: e.isPrimary,
              ))
          .toList(growable: false),
    );
    final dto = await _remoteDatasource.createTillSetup(request);
    return TillMapper.toCreatedEntity(dto);
  }

  @override
  Future<TillDetail> updateTill(String id, TillFormData form) async {
    final dto = await _remoteDatasource.updateTill(id, _toRequestDto(form));
    return TillMapper.toDetailEntity(dto);
  }

  @override
  Future<void> deleteTill(String id) async {
    await _remoteDatasource.deleteTill(id);
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

  CreateTillRequestDto _toRequestDto(TillFormData form) {
    return CreateTillRequestDto(
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
    );
  }

  @override
  Future<TillCreateOptions> getCreateOptions({String? outletId}) async {
    final dto = await _remoteDatasource.getCreateOptions(outletId: outletId);
    return TillCreateOptions(
      outlets: dto.outlets
          .map((e) => TillOutletOption(
                id: e.id,
                name: e.name,
                code: e.code,
                status: e.status,
              ))
          .toList(growable: false),
      cashiers: dto.cashiers
          .map((e) => TillCashierOption(
                id: e.id,
                displayName: e.displayName,
                outletIds: e.outletIds,
              ))
          .toList(growable: false),
      posDevices: dto.posDevices
          .map((e) => TillPosDeviceOption(
                id: e.id,
                code: e.code,
                name: e.name,
                outletId: e.outletId,
                status: e.status,
                isTrusted: e.isTrusted,
                isAssigned: e.isAssigned,
                lastSeenAt: e.lastSeenAt,
              ))
          .toList(growable: false),
      hardwareDevices: dto.hardwareDevices
          .map((e) => TillHardwareDeviceOption(
                id: e.id,
                code: e.code,
                name: e.name,
                type: e.type,
                outletId: e.outletId,
                status: e.status,
                isAssigned: e.isAssigned,
                connectionType: e.connectionType,
                lastSeenAt: e.lastSeenAt,
                connectionStatus: e.connectionStatus,
              ))
          .toList(growable: false),
      statuses: dto.statuses,
      currencyCode: dto.currencyCode,
    );
  }
}
