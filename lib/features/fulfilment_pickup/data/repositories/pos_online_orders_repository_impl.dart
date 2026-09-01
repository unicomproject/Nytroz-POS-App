import 'package:dio/dio.dart';

import '../../domain/entities/pos_online_order.dart';
import '../../domain/repositories/pos_online_orders_repository.dart';
import '../datasources/pos_online_orders_remote_datasource.dart';

class PosOnlineOrdersRepositoryImpl implements PosOnlineOrdersRepository {
  const PosOnlineOrdersRepositoryImpl(this._remote);

  final PosOnlineOrdersRemoteDatasource _remote;

  @override
  Future<PosOnlineOrderPage> list(
    PosOnlineOrdersQuery query, {
    CancelToken? cancelToken,
  }) =>
      _remote.list(query, cancelToken: cancelToken);

  @override
  Future<PosOnlineOrderDetail> get(
          {required String outletId,
          required String orderId,
          CancelToken? cancelToken}) =>
      _remote.get(
          outletId: outletId, orderId: orderId, cancelToken: cancelToken);

  @override
  Future<PosPickingOrder> getPicking(
          {required String outletId,
          required String orderId,
          CancelToken? cancelToken}) =>
      _remote.getPicking(
          outletId: outletId, orderId: orderId, cancelToken: cancelToken);

  @override
  Future<PosStartFulfillmentResult> startFulfillment(
          {required String outletId,
          required String orderId,
          required int expectedVersion,
          CancelToken? cancelToken}) =>
      _remote.startFulfillment(
          outletId: outletId,
          orderId: orderId,
          expectedVersion: expectedVersion,
          cancelToken: cancelToken);

  @override
  Future<PosFulfillmentCommandResult> pickLine(
          {required String outletId,
          required String orderId,
          required String lineId,
          required double quantity,
          required String barcode,
          required bool scanned}) =>
      _remote.pickLine(
          outletId: outletId,
          orderId: orderId,
          lineId: lineId,
          quantity: quantity,
          barcode: barcode,
          scanned: scanned);

  @override
  Future<PosFulfillmentCommandResult> reportIssue(
          {required String outletId,
          required String orderId,
          required String lineId,
          required String reason,
          String? note}) =>
      _remote.reportIssue(
          outletId: outletId,
          orderId: orderId,
          lineId: lineId,
          reason: reason,
          note: note);

  @override
  Future<PosFulfillmentCommandResult> pack(
          {required String outletId,
          required String orderId,
          String? packingNote}) =>
      _remote.pack(
          outletId: outletId, orderId: orderId, packingNote: packingNote);

  @override
  Future<PosFulfillmentCommandResult> markReady(
          {required String outletId, required String orderId}) =>
      _remote.markReady(outletId: outletId, orderId: orderId);
}
