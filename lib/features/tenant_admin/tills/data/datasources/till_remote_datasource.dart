import 'package:dio/dio.dart';

import '../../domain/entities/till.dart';
import '../models/create_till_request_dto.dart';
import '../models/till_dto.dart';

class TillRemoteDatasource {
  const TillRemoteDatasource(this._dio);

  final Dio _dio;

  static const _tillPath = '/api/v1/tenant-admin/tills';
  static const _outletOptionsPath = '/api/v1/tenant-admin/outlets/options';

  Future<TillListResultDto> getTills(TillListQuery query) async {
    final listResponse = await _dio.get<dynamic>(
      _tillPath,
      queryParameters: _listQueryParameters(query),
    );
    final summaryResponse = await _dio.get<dynamic>('$_tillPath/summary');

    final summary = _parseSummary(summaryResponse.data);
    return _parseListResponse(
      listResponse.data,
      listResponse.requestOptions,
      summary: summary,
    );
  }

  Future<CreatedTillDto> createTill(CreateTillRequestDto request) async {
    final response = await _dio.post<dynamic>(
      _tillPath,
      data: request.toJson(),
    );

    return CreatedTillDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<List<OutletOptionDto>> getOutletOptions() async {
    final response = await _dio.get<dynamic>(_outletOptionsPath);
    final data = response.data;

    if (data is! Map) {
      return const [];
    }

    final root = Map<String, dynamic>.from(data);
    final rawItems = root['data'];

    if (rawItems is! List) {
      return const [];
    }

    return rawItems
        .whereType<Map>()
        .map((item) => OutletOptionDto.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Map<String, dynamic> _listQueryParameters(TillListQuery query) {
    return {
      'page': query.page,
      'pageSize': query.pageSize,
      'sortBy': query.sortBy,
      'sortDirection': query.sortDirection,
      if (query.search != null && query.search!.trim().isNotEmpty)
        'search': query.search!.trim(),
      if (query.status != null && query.status!.trim().isNotEmpty)
        'status': query.status!.trim(),
    };
  }

  TillListSummaryDto? _parseSummary(dynamic data) {
    if (data is! Map) {
      return null;
    }

    final root = Map<String, dynamic>.from(data);
    final payload = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;

    return TillListSummaryDto.fromJson(payload);
  }

  TillListResultDto _parseListResponse(
    dynamic data,
    RequestOptions requestOptions, {
    TillListSummaryDto? summary,
  }) {
    if (data is Map && data['success'] == false) {
      throw DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        message: data['message']?.toString(),
      );
    }

    if (data is Map) {
      final root = Map<String, dynamic>.from(data);
      final payload = root['data'] is Map
          ? Map<String, dynamic>.from(root['data'] as Map)
          : root;

      return TillListResultDto.fromJson(payload, summary: summary);
    }

    return TillListResultDto.fromJson(const {}, summary: summary);
  }

  Map<String, dynamic> _unwrapApiPayload(
    dynamic data,
    RequestOptions requestOptions,
  ) {
    if (data is! Map) {
      return const {};
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

    if (root['data'] is Map) {
      return Map<String, dynamic>.from(root['data'] as Map);
    }

    return root;
  }
}
