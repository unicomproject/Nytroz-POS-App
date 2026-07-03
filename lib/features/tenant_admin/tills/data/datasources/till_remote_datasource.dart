import 'package:dio/dio.dart';

import '../../domain/entities/till.dart';
import '../models/create_till_request_dto.dart';
import '../models/till_dto.dart';

class TillRemoteDatasource {
  const TillRemoteDatasource(this._dio);

  final Dio _dio;

  static const _tillPath = '/api/v1/tenant-admin/tills';

  Future<TillListResultDto> getTills(TillListQuery query) async {
    final response = await _dio.get<dynamic>(
      _tillPath,
      queryParameters: _listQueryParameters(query),
    );

    return _parseListResponse(response.data, response.requestOptions);
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

  TillListResultDto _parseListResponse(
    dynamic data,
    RequestOptions requestOptions,
  ) {
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
