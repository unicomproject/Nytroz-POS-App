import '../../data/models/pos_parked_sale_dtos.dart';

abstract interface class PosParkedSaleRepository {
  Future<PosHoldDto> create(PosCreateHoldRequestDto request);
  Future<PosHoldListDto> list({
    required String deviceId,
    required String scope,
    required int page,
    required int pageSize,
  });
  Future<PosRecallHoldDto> recall(String holdId, String deviceId);
  Future<void> cancel(String holdId, {String? reason});
}
