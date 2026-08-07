import '../../domain/repositories/pos_parked_sale_repository.dart';
import '../datasources/pos_parked_sale_remote_datasource.dart';
import '../models/pos_parked_sale_dtos.dart';

class PosParkedSaleRepositoryImpl implements PosParkedSaleRepository {
  const PosParkedSaleRepositoryImpl(this.remote);
  final PosParkedSaleRemoteDatasource remote;
  @override
  Future<PosHoldDto> create(PosCreateHoldRequestDto request) =>
      remote.create(request);
  @override
  Future<PosHoldListDto> list({
    required String deviceId,
    required String scope,
    required int page,
    required int pageSize,
  }) =>
      remote.list(
        deviceId: deviceId,
        scope: scope,
        page: page,
        pageSize: pageSize,
      );
  @override
  Future<PosRecallHoldDto> recall(String holdId, String deviceId) =>
      remote.recall(holdId, deviceId);
  @override
  Future<void> cancel(String holdId, {String? reason}) =>
      remote.cancel(holdId, reason: reason);
}
