import 'package:dio/dio.dart';

import 'package:nytroz_pos/core/network/api_endpoints.dart';
import '../../../domain/entities/pos_barcode_lookup_result.dart';

abstract interface class PosBarcodeLookupGateway {
  Future<PosBarcodeLookupResult> getProductByBarcode({
    required String deviceId,
    required String barcode,
  });
}

class PosBarcodeRemoteDatasource implements PosBarcodeLookupGateway {
  const PosBarcodeRemoteDatasource(this._dio);

  final Dio _dio;

  @override
  Future<PosBarcodeLookupResult> getProductByBarcode({
    required String deviceId,
    required String barcode,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.posProductByBarcode(barcode),
      queryParameters: {'deviceId': deviceId},
    );
    final envelope = response.data ?? const <String, dynamic>{};
    final raw = envelope['data'];
    if (raw is! Map) {
      throw const FormatException('Missing exact barcode response data.');
    }
    return PosBarcodeLookupResult.fromJson(Map<String, dynamic>.from(raw));
  }
}
