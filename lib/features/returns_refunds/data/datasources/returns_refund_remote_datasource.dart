import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../../domain/entities/return_receipt.dart';
import '../../domain/entities/return_sale_eligibility.dart';
import '../../domain/entities/return_sale_summary.dart';

class ReturnsRefundRemoteDatasource {
  const ReturnsRefundRemoteDatasource(this._dio);

  final Dio _dio;

  Future<ReturnSaleSearchPage> searchOriginalSales({
    required String deviceId,
    String? search,
    required String searchType,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleSearch,
        queryParameters: {
          'deviceId': deviceId,
          'searchType': searchType,
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnSaleSearchPage.fromJson(data);
      }

      return const ReturnSaleSearchPage(
        items: [],
        page: 1,
        pageSize: 20,
        totalCount: 0,
      );
    } on DioException catch (error) {
      developer.log(
        'Return sale search API failed. endpoint=${ApiEndpoints.posReturnSaleSearch}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.search',
      );
      rethrow;
    }
  }

  Future<ReturnSaleEligibility> getSaleEligibility({
    required String deviceId,
    required String saleId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleEligibility(saleId),
        queryParameters: {'deviceId': deviceId},
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnSaleEligibility.fromJson(data);
      }

      throw StateError('Unexpected sale eligibility response.');
    } on DioException catch (error) {
      developer.log(
        'Return sale eligibility API failed. endpoint=${ApiEndpoints.posReturnSaleEligibility(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.eligibility',
      );
      rethrow;
    }
  }

  Future<ReturnCreditPreview> getCreditPreview({
    required String deviceId,
    required String saleId,
    required String reasonCode,
    required List<Map<String, dynamic>> lines,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleCreditPreview(saleId),
        queryParameters: {'deviceId': deviceId},
        data: {
          'reasonCode': reasonCode,
          'lines': lines,
        },
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnCreditPreview.fromJson(data);
      }

      throw StateError('Unexpected credit preview response.');
    } on DioException catch (error) {
      developer.log(
        'Return credit preview API failed. endpoint=${ApiEndpoints.posReturnSaleCreditPreview(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.credit_preview',
      );
      rethrow;
    }
  }

  Future<ReturnReceipt> completeReturn({
    required String deviceId,
    required String saleId,
    required String reasonCode,
    required String settlementMethodCode,
    required String? notes,
    required List<Map<String, dynamic>> lines,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleComplete(saleId),
        queryParameters: {'deviceId': deviceId},
        data: {
          'reasonCode': reasonCode,
          'settlementMethodCode': settlementMethodCode,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          'lines': lines,
        },
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnReceipt.fromJson(data);
      }

      throw StateError('Unexpected return complete response.');
    } on DioException catch (error) {
      developer.log(
        'Return complete API failed. endpoint=${ApiEndpoints.posReturnSaleComplete(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.complete',
      );
      rethrow;
    }
  }

  Object _unwrapApiData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return json;
  }
}
