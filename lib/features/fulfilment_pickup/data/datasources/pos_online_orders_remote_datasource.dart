import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/pos_online_order.dart';

class PosOnlineOrdersRemoteDatasource {
  const PosOnlineOrdersRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PosOnlineOrderPage> list(
    PosOnlineOrdersQuery query, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.posOnlineOrders,
      queryParameters: query.toQueryParameters(),
      cancelToken: cancelToken,
    );
    final root = response.data ?? const <String, dynamic>{};
    final data = root['data'];
    final pagination = root['pagination'];
    if (data is! List) {
      throw StateError('Unexpected online order list API response.');
    }
    return PosOnlineOrderPage.fromJson({
      'items': data,
      'summary': root['summary'],
      'serverTime': root['serverTime'],
      if (pagination is Map) ...Map<String, dynamic>.from(pagination),
    });
  }

  Future<PosOnlineOrderDetail> get({
    required String outletId,
    required String orderId,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.posOnlineOrder(orderId),
      queryParameters: {'outletId': outletId},
      cancelToken: cancelToken,
    );
    return PosOnlineOrderDetail.fromJson(_data(response.data));
  }

  Future<PosStartFulfillmentResult> startFulfillment({
    required String outletId,
    required String orderId,
    required int expectedVersion,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.posOnlineOrderStartFulfillment(orderId),
      queryParameters: {'outletId': outletId},
      data: {'expectedVersion': expectedVersion},
      cancelToken: cancelToken,
    );
    return PosStartFulfillmentResult.fromJson(_data(response.data));
  }

  Future<PosPickingOrder> getPicking({
    required String outletId,
    required String orderId,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.posOnlineOrderPicking(orderId),
      queryParameters: {'outletId': outletId},
      cancelToken: cancelToken,
    );
    return PosPickingOrder.fromJson(_data(response.data));
  }

  Future<PosFulfillmentCommandResult> pickLine(
          {required String outletId,
          required String orderId,
          required String lineId,
          required double quantity,
          required String barcode,
          required bool scanned}) =>
      _command(ApiEndpoints.posOnlineOrderPickLine(orderId, lineId), outletId, {
        'quantity': quantity,
        'barcode': barcode,
        'inputMethod': scanned ? 'SCAN' : 'MANUAL',
      });

  Future<PosFulfillmentCommandResult> reportIssue(
          {required String outletId,
          required String orderId,
          required String lineId,
          required String reason,
          String? note}) =>
      _command(ApiEndpoints.posOnlineOrderPickingIssue(orderId, lineId),
          outletId, {'reason': reason, 'note': note});

  Future<PosFulfillmentCommandResult> pack(
          {required String outletId,
          required String orderId,
          String? packingNote}) =>
      _command(ApiEndpoints.posOnlineOrderPack(orderId), outletId,
          {'packingNote': packingNote});

  Future<PosFulfillmentCommandResult> markReady(
          {required String outletId, required String orderId}) =>
      _command(ApiEndpoints.posOnlineOrderReady(orderId), outletId, const {});

  Future<PosFulfillmentCommandResult> _command(
      String path, String outletId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(path,
        queryParameters: {'outletId': outletId}, data: body);
    return PosFulfillmentCommandResult.fromJson(_data(response.data));
  }

  Map<String, dynamic> _data(Map<String, dynamic>? root) {
    final data = root?['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    throw StateError('Unexpected online order API response.');
  }
}
