import 'package:dio/dio.dart';

import '../entities/pos_online_order.dart';

abstract interface class PosOnlineOrdersRepository {
  Future<PosOnlineOrderPage> list(
    PosOnlineOrdersQuery query, {
    CancelToken? cancelToken,
  });

  Future<PosOnlineOrderDetail> get({
    required String outletId,
    required String orderId,
    CancelToken? cancelToken,
  });

  Future<PosStartFulfillmentResult> startFulfillment({
    required String outletId,
    required String orderId,
    required int expectedVersion,
    CancelToken? cancelToken,
  });

  Future<PosPickingOrder> getPicking({
    required String outletId,
    required String orderId,
    CancelToken? cancelToken,
  });

  Future<PosFulfillmentCommandResult> pickLine({
    required String outletId,
    required String orderId,
    required String lineId,
    required double quantity,
    required String barcode,
    required bool scanned,
  });

  Future<PosFulfillmentCommandResult> reportIssue({
    required String outletId,
    required String orderId,
    required String lineId,
    required String reason,
    String? note,
  });

  Future<PosFulfillmentCommandResult> pack({
    required String outletId,
    required String orderId,
    String? packingNote,
  });

  Future<PosFulfillmentCommandResult> markReady({
    required String outletId,
    required String orderId,
  });
}
