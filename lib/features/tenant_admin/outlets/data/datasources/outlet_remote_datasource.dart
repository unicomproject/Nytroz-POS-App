import 'package:dio/dio.dart';

import '../models/create_outlet_request_dto.dart';
import '../models/outlet_dto.dart';

class OutletRemoteDatasource {
  const OutletRemoteDatasource(this._dio);

  final Dio _dio;

  static const _outletPaths = [
    '/api/v1/tenant-admin/outlets',
    '/api/tenant-admin/outlets',
  ];

  Future<OutletListResultDto> getOutlets({String? search}) async {
    DioException? lastError;

    for (final path in _outletPaths) {
      try {
        final response = await _dio.get<dynamic>(
          path,
          queryParameters: {
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
          },
        );

        return _parseListResponse(response.data, response.requestOptions);
      } on DioException catch (error) {
        lastError = error;
        if (error.response?.statusCode == 404) {
          continue;
        }

        rethrow;
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    return OutletListResultDto.fromArray(const []);
  }

  Future<OutletDetailsDto> getOutletDetails(String id) async {
    return _requestOutletDetails(
      (path) => _dio.get<dynamic>('$path/$id'),
    );
  }

  Future<OutletDetailsDto> createOutlet(CreateOutletRequestDto request) async {
    return _requestOutletDetails(
      (path) => _dio.post<dynamic>(path, data: request.toJson()),
    );
  }

  Future<OutletDetailsDto> updateOutlet(
    String id,
    CreateOutletRequestDto request,
  ) async {
    return _requestOutletDetails(
      (path) => _dio.put<dynamic>('$path/$id', data: request.toJson()),
    );
  }

  Future<void> updateOutletStatus(String id, String status) async {
    DioException? lastError;

    for (final path in _outletPaths) {
      try {
        await _dio.patch<void>(
          '$path/$id/status',
          data: {'status': status},
        );
        return;
      } on DioException catch (error) {
        lastError = error;
        if (error.response?.statusCode == 404) {
          continue;
        }

        rethrow;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  Future<List<OutletManagerOptionDto>> getManagerOptions() async {
    final response = await _dio.get<dynamic>(
      '/api/tenant-admin/staff/managers',
    );
    final data = response.data;
    final items = data is Map ? data['items'] : data;

    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map>()
        .map((item) => OutletManagerOptionDto.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<OutletDetailsDto> _requestOutletDetails(
    Future<Response<dynamic>> Function(String path) request,
  ) async {
    DioException? lastError;

    for (final path in _outletPaths) {
      try {
        final response = await request(path);
        return OutletDetailsDto.fromJson(
          _unwrapApiPayload(response.data, response.requestOptions),
        );
      } on DioException catch (error) {
        lastError = error;
        if (error.response?.statusCode == 404) {
          continue;
        }

        rethrow;
      }
    }

    throw lastError ??
        DioException(
          requestOptions: RequestOptions(path: _outletPaths.first),
          type: DioExceptionType.badResponse,
          message: 'Outlet API is unavailable.',
        );
  }

  OutletListResultDto _parseListResponse(
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

    if (data is List) {
      return OutletListResultDto.fromArray(data);
    }

    if (data is Map) {
      final root = Map<String, dynamic>.from(data);
      final payload = root['data'] is Map
          ? Map<String, dynamic>.from(root['data'] as Map)
          : root;

      return OutletListResultDto.fromJson(payload);
    }

    return OutletListResultDto.fromArray(const []);
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
