import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../domain/entities/till_list_query.dart';
import '../models/create_till_request_dto.dart';
import '../models/till_dto.dart';

class TillRemoteDatasource {
  const TillRemoteDatasource(this._dio);

  final Dio _dio;

  Future<TillListResultDto> getTills(TillListQuery query) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.tenantAdminTills,
      queryParameters: _listQueryParameters(query),
    );

    return _parseListResponse(response.data, response.requestOptions);
  }

  Future<TillDto> createTill(CreateTillRequestDto request) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.tenantAdminTills,
      data: request.toJson(),
    );

    return TillDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
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

  TillListResultDto _parseListResponse(dynamic data, RequestOptions requestOptions) {
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

      return TillListResultDto.fromJson(payload);
    }

    return TillListResultDto.fromJson(const {});
  }

  Map<String, dynamic> _unwrapApiPayload(dynamic data, RequestOptions requestOptions) {
    if (data is! Map) {
      return const {};
    }

    final root = Map<String, dynamic>.from(data);
    if (root['success'] == false) {
      throw DioException(
        requestOptions: requestOptions,
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
