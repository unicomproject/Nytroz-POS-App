import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/return_resolution.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../../domain/entities/return_inspection.dart';
import '../../domain/entities/return_reason_option.dart';
import '../../domain/entities/return_exchange.dart';
import '../../domain/entities/return_receipt.dart';
import '../../domain/entities/return_refund_method.dart';
import '../../domain/entities/return_sale_eligibility.dart';
import '../../domain/entities/return_sale_summary.dart';

class ReturnsRefundRemoteDatasource {
  const ReturnsRefundRemoteDatasource(this._dio);

  final Dio _dio;

  Future<ReturnSaleSearchPage> searchOriginalSales({
    required String deviceId,
    String? search,
    required String searchType,
    DateTime? fromDate,
    DateTime? toDate,
    String? paymentMethodCode,
    double? minAmount,
    double? maxAmount,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleSearch,
        queryParameters: {
          'deviceId': deviceId,
          'searchType': searchType,
          'page': page,
          'pageSize': pageSize,
          if (fromDate != null) 'fromDate': _formatDateOnly(fromDate),
          if (toDate != null) 'toDate': _formatDateOnly(toDate),
          if (paymentMethodCode != null &&
              paymentMethodCode.trim().isNotEmpty)
            'paymentMethodCode': paymentMethodCode.trim(),
          if (minAmount != null) 'minAmount': minAmount,
          if (maxAmount != null) 'maxAmount': maxAmount,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
        cancelToken: cancelToken,
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

  static String _formatDateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<ReturnSaleEligibility> getSaleEligibility({
    required String deviceId,
    required String saleId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleEligibility(saleId),
        queryParameters: {'deviceId': deviceId},
        cancelToken: cancelToken,
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

  Future<List<ReturnReasonOption>> getReturnReasons({
    required String deviceId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posReturnReasons,
        queryParameters: {'deviceId': deviceId},
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is List) {
        return data
            .whereType<Map>()
            .map((raw) => ReturnReasonOption.fromJson(
                  Map<String, dynamic>.from(raw),
                ))
            .toList(growable: false);
      }

      return const [];
    } on DioException catch (error) {
      developer.log(
        'Return reasons API failed. endpoint=${ApiEndpoints.posReturnReasons}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.reasons',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> validateReturnReasons({
    required String deviceId,
    required String saleId,
    required bool applySameReasonToAll,
    required List<Map<String, dynamic>> items,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleReasonsValidate(saleId),
        queryParameters: {'deviceId': deviceId},
        data: {
          'applySameReasonToAll': applySameReasonToAll,
          'items': items,
        },
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return data;
      }

      throw StateError('Unexpected return reasons validate response.');
    } on DioException catch (error) {
      developer.log(
        'Return reasons validate API failed. '
        'endpoint=${ApiEndpoints.posReturnSaleReasonsValidate(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.reasons_validate',
      );
      rethrow;
    }
  }

  Future<ReturnSaleEligibility> checkSelectedSaleEligibility({
    required String deviceId,
    required String saleId,
    required List<Map<String, dynamic>> lines,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleEligibilityCheck(saleId),
        queryParameters: {'deviceId': deviceId},
        data: {'lines': lines},
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnSaleEligibility.fromJson(data);
      }

      throw StateError('Unexpected eligibility check response.');
    } on DioException catch (error) {
      developer.log(
        'Return sale eligibility check API failed. endpoint=${ApiEndpoints.posReturnSaleEligibilityCheck(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.eligibility_check',
      );
      rethrow;
    }
  }

  Future<ReturnCreditPreview> getCreditPreview({
    required String deviceId,
    required String saleId,
    required String reasonCode,
    required List<Map<String, dynamic>> lines,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleCreditPreview(saleId),
        queryParameters: {'deviceId': deviceId},
        data: {
          'reasonCode': reasonCode,
          'lines': lines,
        },
        cancelToken: cancelToken,
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
    required int expectedVersion,
    required String idempotencyKey,
    CancelToken? cancelToken,
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
          'expectedVersion': expectedVersion,
          'idempotencyKey': idempotencyKey,
        },
        cancelToken: cancelToken,
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

  Future<ReturnReceipt> getCompletion({
    required String deviceId,
    required String returnId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posReturnCompletion(returnId),
        queryParameters: {'deviceId': deviceId},
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnReceipt.fromJson(data);
      }

      throw StateError('Unexpected return completion response.');
    } on DioException catch (error) {
      developer.log(
        'Return completion API failed. endpoint=${ApiEndpoints.posReturnCompletion(returnId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.completion',
      );
      rethrow;
    }
  }

  Future<void> recordReceiptPrint({required String saleId}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posReceiptPrint(saleId),
        data: const {
          'status': 'success',
          'copies': 1,
        },
      );
    } on DioException catch (error) {
      developer.log(
        'Return receipt print API failed. endpoint=${ApiEndpoints.posReceiptPrint(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.print',
      );
      rethrow;
    }
  }

  Future<ReturnResolution> saveResolution({
    required String deviceId,
    required String saleId,
    required String resolution,
    required int expectedVersion,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleResolution(saleId),
        queryParameters: {'deviceId': deviceId},
        data: {
          'resolutionType': resolution,
          'expectedVersion': expectedVersion,
        },
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnResolution.fromJson(data);
      }

      throw StateError('Unexpected resolution save response.');
    } on DioException catch (error) {
      developer.log(
        'Return resolution save API failed. endpoint=${ApiEndpoints.posReturnSaleResolution(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.resolution_save',
      );
      rethrow;
    }
  }

  Future<ReturnResolution> getResolution({
    required String deviceId,
    required String saleId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleResolution(saleId),
        queryParameters: {'deviceId': deviceId},
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnResolution.fromJson(data);
      }

      throw StateError('Unexpected resolution response.');
    } on DioException catch (error) {
      developer.log(
        'Return resolution API failed. endpoint=${ApiEndpoints.posReturnSaleResolution(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.resolution',
      );
      rethrow;
    }
  }

  Future<ReturnRefundMethodsResponse> getRefundMethods({
    required String deviceId,
    required String saleId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleRefundMethods(saleId),
        queryParameters: {'deviceId': deviceId},
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnRefundMethodsResponse.fromJson(data);
      }

      throw StateError('Unexpected refund methods response.');
    } on DioException catch (error) {
      developer.log(
        'Return refund methods API failed. endpoint=${ApiEndpoints.posReturnSaleRefundMethods(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.refund_methods',
      );
      rethrow;
    }
  }

  Future<ReturnRefundMethodSaveResponse> saveRefundMethod({
    required String deviceId,
    required String saleId,
    required String methodCode,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleRefundMethod(saleId),
        queryParameters: {'deviceId': deviceId},
        data: {'methodCode': methodCode},
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnRefundMethodSaveResponse.fromJson(data);
      }

      throw StateError('Unexpected refund method save response.');
    } on DioException catch (error) {
      developer.log(
        'Return refund method save API failed. endpoint=${ApiEndpoints.posReturnSaleRefundMethod(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.refund_method_save',
      );
      rethrow;
    }
  }

  Future<ReturnExchangeProductsResponse> searchExchangeProducts({
    required String deviceId,
    required String saleId,
    String? search,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleExchangeProducts(saleId),
        queryParameters: {
          'deviceId': deviceId,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'page': page,
          'pageSize': pageSize,
        },
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnExchangeProductsResponse.fromJson(data);
      }

      throw StateError('Unexpected exchange products response.');
    } on DioException catch (error) {
      developer.log(
        'Exchange products API failed. endpoint=${ApiEndpoints.posReturnSaleExchangeProducts(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.exchange_products',
      );
      rethrow;
    }
  }

  Future<ReturnExchangeReplacementResponse> saveExchangeReplacement({
    required String deviceId,
    required String saleId,
    required List<Map<String, dynamic>> items,
    required int expectedVersion,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleExchangeReplacement(saleId),
        queryParameters: {'deviceId': deviceId},
        data: {
          'expectedVersion': expectedVersion,
          'items': items,
        },
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnExchangeReplacementResponse.fromJson(data);
      }

      throw StateError('Unexpected exchange replacement save response.');
    } on DioException catch (error) {
      developer.log(
        'Exchange replacement save API failed. endpoint=${ApiEndpoints.posReturnSaleExchangeReplacement(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.exchange_replacement_save',
      );
      rethrow;
    }
  }

  Future<ReturnExchangeReplacementResponse> getExchangeReplacement({
    required String deviceId,
    required String saleId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleExchangeReplacement(saleId),
        queryParameters: {'deviceId': deviceId},
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnExchangeReplacementResponse.fromJson(data);
      }

      throw StateError('Unexpected exchange replacement response.');
    } on DioException catch (error) {
      developer.log(
        'Exchange replacement API failed. endpoint=${ApiEndpoints.posReturnSaleExchangeReplacement(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.exchange_replacement',
      );
      rethrow;
    }
  }

  Future<ReturnExchangePreview> getExchangePreview({
    required String deviceId,
    required String saleId,
    required String reasonCode,
    required List<Map<String, dynamic>> lines,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleExchangePreview(saleId),
        queryParameters: {'deviceId': deviceId},
        data: {
          'reasonCode': reasonCode,
          'lines': lines,
        },
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return ReturnExchangePreview.fromJson(data);
      }

      throw StateError('Unexpected exchange preview response.');
    } on DioException catch (error) {
      developer.log(
        'Exchange preview API failed. endpoint=${ApiEndpoints.posReturnSaleExchangePreview(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.exchange_preview',
      );
      rethrow;
    }
  }

  Future<List<InspectionConditionOption>> getInspectionConditions({
    required String deviceId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posReturnInspectionConditions,
        queryParameters: {'deviceId': deviceId},
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(InspectionConditionOption.fromJson)
            .toList(growable: false);
      }

      return const [];
    } on DioException catch (error) {
      developer.log(
        'Return inspection conditions API failed. endpoint=${ApiEndpoints.posReturnInspectionConditions}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.inspection_conditions',
      );
      rethrow;
    }
  }

  Future<InspectionValidationResult> validateInspection({
    required String deviceId,
    required String saleId,
    required List<Map<String, dynamic>> lines,
    List<Map<String, dynamic>>? reasonRefs,
    int? version,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleInspectionValidate(saleId),
        queryParameters: {'deviceId': deviceId},
        data: {
          'lines': lines,
          if (reasonRefs != null && reasonRefs.isNotEmpty)
            'reasonRefs': reasonRefs,
          if (version != null) 'version': version,
        },
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return InspectionValidationResult.fromJson(data);
      }

      throw StateError('Unexpected inspection validation response.');
    } on DioException catch (error) {
      developer.log(
        'Return inspection validate API failed. endpoint=${ApiEndpoints.posReturnSaleInspectionValidate(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.inspection_validate',
      );
      rethrow;
    }
  }

  Future<InspectionDraft> saveInspectionDraft({
    required String deviceId,
    required String saleId,
    required List<Map<String, dynamic>> lines,
    int? version,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleInspectionDraft(saleId),
        queryParameters: {'deviceId': deviceId},
        data: {
          'lines': lines,
          if (version != null) 'version': version,
        },
        cancelToken: cancelToken,
      );
      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return InspectionDraft.fromJson(data);
      }
      throw StateError('Unexpected inspection draft response.');
    } on DioException catch (error) {
      developer.log(
        'Return inspection draft save failed. endpoint=${ApiEndpoints.posReturnSaleInspectionDraft(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.inspection_draft_save',
      );
      rethrow;
    }
  }

  Future<InspectionDraft?> getInspectionDraft({
    required String deviceId,
    required String saleId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleInspectionDraft(saleId),
        queryParameters: {'deviceId': deviceId},
        cancelToken: cancelToken,
      );
      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        return InspectionDraft.fromJson(data);
      }
      throw StateError('Unexpected inspection draft response.');
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      developer.log(
        'Return inspection draft load failed. endpoint=${ApiEndpoints.posReturnSaleInspectionDraft(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.inspection_draft_load',
      );
      rethrow;
    }
  }

  Future<List<int>> fetchInspectionMediaBytes({
    required String deviceId,
    required String mediaId,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<List<int>>(
      ApiEndpoints.posReturnInspectionMedia(mediaId),
      queryParameters: {'deviceId': deviceId},
      options: Options(responseType: ResponseType.bytes),
      cancelToken: cancelToken,
    );
    return response.data ?? const [];
  }

  Future<InspectionMediaItem> uploadInspectionMedia({
    required String deviceId,
    required String saleId,
    required String saleLineId,
    required String filePath,
    required String fileName,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posReturnSaleInspectionMedia(saleId),
        queryParameters: {
          'deviceId': deviceId,
          'saleLineId': saleLineId,
        },
        data: formData,
        cancelToken: cancelToken,
      );

      final data = _unwrapApiData(response.data ?? const {});
      if (data is Map<String, dynamic>) {
        final mediaId = data['mediaId']?.toString() ?? '';
        final mediaUrl = data['mediaUrl']?.toString() ?? '';
        return InspectionMediaItem(
          mediaId: mediaId,
          previewUrl: _resolveMediaUrl(mediaUrl),
          localPath: filePath,
        );
      }

      throw StateError('Unexpected inspection media upload response.');
    } on DioException catch (error) {
      developer.log(
        'Return inspection media upload failed. endpoint=${ApiEndpoints.posReturnSaleInspectionMedia(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.inspection_media',
      );
      rethrow;
    }
  }

  Future<void> deleteInspectionMedia({
    required String deviceId,
    required String mediaId,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.delete<void>(
        ApiEndpoints.posReturnInspectionMedia(mediaId),
        queryParameters: {'deviceId': deviceId},
        cancelToken: cancelToken,
      );
    } on DioException catch (error) {
      developer.log(
        'Return inspection media delete failed. endpoint=${ApiEndpoints.posReturnInspectionMedia(mediaId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'returns_refunds.inspection_media_delete',
      );
      rethrow;
    }
  }

  String _resolveMediaUrl(String mediaUrl) {
    if (mediaUrl.startsWith('http')) {
      return mediaUrl;
    }
    final baseUrl = _dio.options.baseUrl;
    if (baseUrl.isEmpty) {
      return mediaUrl;
    }
    return '$baseUrl$mediaUrl';
  }

  Object _unwrapApiData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return json;
  }
}
