import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../domain/receipt_history_models.dart';

class ReceiptRemoteDatasource {
  const ReceiptRemoteDatasource(this._dio);
  final Dio _dio;

  Future<({List<ReceiptHistoryItem> items, int total})> search({
    String? query,
    int page = 1,
    int pageSize = 25,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.posReceipts,
      queryParameters: {
        if (query?.trim().isNotEmpty == true) 'query': query!.trim(),
        'pageNumber': page,
        'pageSize': pageSize,
      },
    );
    final data = _data(response.data);
    return (
      items: (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => ReceiptHistoryItem.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
      total: (data['totalCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<ReceiptDetail> detail(String receiptId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.posReceiptDetail(receiptId),
    );
    return ReceiptDetail.fromJson(_data(response.data));
  }

  Future<String> authorizeReprint({
    required String receiptId,
    required String reasonCode,
    String? reasonNote,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.posReceiptReprintAuthorize(receiptId),
      data: {'reasonCode': reasonCode, 'reasonNote': reasonNote},
    );
    return '${_data(response.data)['operationId'] ?? ''}';
  }

  Future<void> recordPrintAudit({
    required String saleId,
    required Map<String, dynamic> audit,
  }) async {
    await _dio.post('/api/v1/pos/receipts/$saleId/print', data: audit);
  }

  Map<String, dynamic> _data(Map<String, dynamic>? body) {
    final value = body?['data'];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const FormatException('Receipt API returned malformed data.');
  }
}
