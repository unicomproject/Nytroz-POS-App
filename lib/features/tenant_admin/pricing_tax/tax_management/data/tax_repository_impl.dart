import 'package:dio/dio.dart';

import '../domain/tax_aggregate.dart';
import 'tax_dtos.dart';
import 'tax_repository.dart';

class TaxRepositoryImpl implements TaxRepository {
  const TaxRepositoryImpl(this._dio);

  final Dio _dio;
  static const _basePath = '/api/v1/tax';

  @override
  Future<TaxSetupListResult> listTaxSetups(TaxSetupListQuery query) async {
    final response = await _dio.get<dynamic>(
      _basePath,
      queryParameters: {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.status != null) 'status': query.status!.apiValue,
        'pageNumber': query.pageNumber,
        'pageSize': query.pageSize,
      },
    );

    return TaxSetupListResultDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    ).toDomain();
  }

  @override
  Future<TaxSetup> getTaxSetup(String id) async {
    final response = await _dio.get<dynamic>('$_basePath/$id');
    return TaxSetupDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    ).toDomain();
  }

  @override
  Future<String> createTaxSetup(TaxSetupCreateInput input) async {
    final response = await _dio.post<dynamic>(
      _basePath,
      data: TaxSetupCreateRequestDto(
        name: input.name,
        code: input.code,
        description: input.description,
        taxTreatment: input.taxTreatment,
        initialRate: input.initialRate,
        effectiveFrom: input.effectiveFrom,
      ).toJson(),
    );

    final payload = _unwrapFlexiblePayload(
      response.data,
      response.requestOptions,
    );
    if (payload is String && payload.trim().isNotEmpty) {
      return payload.trim();
    }
    if (payload is Map) {
      final id = payload['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    return response.data?.toString() ?? '';
  }

  @override
  Future<void> updateTaxSetup(String id, TaxSetupUpdateInput input) async {
    await _dio.put<dynamic>(
      '$_basePath/$id',
      data: TaxSetupUpdateRequestDto(
        name: input.name,
        code: input.code,
        description: input.description,
        taxTreatment: input.taxTreatment,
      ).toJson(),
    );
  }

  @override
  Future<void> scheduleRate(String id, TaxRateScheduleInput input) async {
    await _dio.post<dynamic>(
      '$_basePath/$id/rates',
      data: TaxRateScheduleRequestDto(
        newRate: input.newRate,
        effectiveFrom: input.effectiveFrom,
        notes: input.notes,
      ).toJson(),
    );
  }

  @override
  Future<void> updateScheduledRate(
    String id,
    String rateId,
    TaxRateScheduleInput input,
  ) async {
    await _dio.put<dynamic>(
      '$_basePath/$id/rates/$rateId',
      data: TaxRateScheduleRequestDto(
        newRate: input.newRate,
        effectiveFrom: input.effectiveFrom,
        notes: input.notes,
      ).toJson(),
    );
  }

  @override
  Future<void> deleteScheduledRate(String id, String rateId) async {
    await _dio.delete<dynamic>('$_basePath/$id/rates/$rateId');
  }

  @override
  Future<TaxStatusChangeResult> activateTaxSetup(String id) async {
    final response = await _dio.post<dynamic>('$_basePath/$id/activate');
    return TaxStatusChangeResultDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    ).toDomain();
  }

  @override
  Future<TaxStatusChangeResult> deactivateTaxSetup(
    String id, {
    String? reason,
  }) async {
    final response = await _dio.post<dynamic>(
      '$_basePath/$id/deactivate',
      data: reason == null || reason.trim().isEmpty
          ? null
          : {'reason': reason.trim()},
    );
    return TaxStatusChangeResultDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    ).toDomain();
  }

  @override
  Future<TaxProductUsingListResult> listProductsUsing(
    String id,
    TaxProductsQuery query,
  ) async {
    final response = await _dio.get<dynamic>(
      '$_basePath/$id/products',
      queryParameters: {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        'pageNumber': query.pageNumber,
        'pageSize': query.pageSize,
      },
    );

    return TaxProductUsingListResultDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    ).toDomain();
  }

  Map<String, dynamic> _unwrapApiPayload(
    dynamic data,
    RequestOptions requestOptions,
  ) {
    final flexible = _unwrapFlexiblePayload(data, requestOptions);
    if (flexible is Map) {
      return Map<String, dynamic>.from(flexible);
    }
    return const {};
  }

  dynamic _unwrapFlexiblePayload(
    dynamic data,
    RequestOptions requestOptions,
  ) {
    if (data is String) {
      return data;
    }

    if (data is! Map) {
      return data;
    }

    final root = Map<String, dynamic>.from(data);
    if (root['success'] == false) {
      throw DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          data: root,
          statusCode: 400,
        ),
        type: DioExceptionType.badResponse,
        message: root['message']?.toString(),
      );
    }

    if (root.containsKey('data')) {
      return root['data'];
    }

    return root;
  }
}
