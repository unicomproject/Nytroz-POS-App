import 'package:dio/dio.dart';

import '../../domain/entities/outlet_list_query.dart';
import '../models/create_outlet_request_dto.dart';
import '../models/outlet_detail_dtos.dart';
import '../models/outlet_create_options_dto.dart';
import '../models/outlet_dto.dart';

class OutletRemoteDatasource {
  const OutletRemoteDatasource(this._dio);

  final Dio _dio;

  static const _outletBase = '/api/v1/outlets';

  Future<OutletListResultDto> getOutlets(OutletListQuery query) async {
    final response = await _dio.get<dynamic>(
      _outletBase,
      queryParameters: _listQueryParameters(query),
    );

    return _parseListResponse(response.data, response.requestOptions);
  }

  Future<OutletCreateOptionsDto> getCreateOptions() async {
    final response = await _dio.get<dynamic>('$_outletBase/create-options');
    return OutletCreateOptionsDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<OutletDetailsDto> getOutletDetails(String id) async {
    final response = await _dio.get<dynamic>('$_outletBase/$id');
    return OutletDetailsDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<OutletDetailsDto> createOutlet(CreateOutletRequestDto request) async {
    final response = await _dio.post<dynamic>(
      _outletBase,
      data: request.toJson(),
    );
    return OutletDetailsDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<OutletDetailsDto> updateOutlet(
    String id,
    CreateOutletRequestDto request,
  ) async {
    final response = await _dio.put<dynamic>(
      '$_outletBase/$id',
      data: request.toJson(),
    );
    return OutletDetailsDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<void> deleteOutlet(String id) async {
    await _dio.delete<void>('$_outletBase/$id');
  }

  Future<void> updateOutletStatus(String id, String status) async {
    final _ = (id, status);
    throw UnsupportedError(
      'Outlet status PATCH is not supported by the current backend contract. '
      'Use the outlet edit flow, which sends PUT /api/v1/outlets/{id}.',
    );
  }

  Future<List<OutletManagerOptionDto>> getManagerOptions() async {
    return const [];
  }

  Map<String, dynamic> _listQueryParameters(OutletListQuery query) {
    return {
      'page': query.page,
      'pageNumber': query.page,
      'pageSize': query.pageSize,
      if (query.search != null && query.search!.trim().isNotEmpty)
        'search': query.search!.trim(),
    };
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

  Future<OutletDetailDto> getOutletDetail(String id) async {
    final response = await _dio.get<dynamic>('$_outletBase/$id');
    return OutletDetailDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<OutletRevenueSummaryDto> getOutletRevenueSummary(String id) async {
    throw UnsupportedError(
      'Outlet revenue summary is not supported by the current backend contract.',
    );
  }

  Future<OutletAssignedUsersDto> getOutletAssignedUsers(String id) async {
    throw UnsupportedError(
      'Outlet assigned users are not supported by the current backend contract.',
    );
  }

  Future<OutletTillsDetailDto> getOutletTillsDetail(String id) async {
    throw UnsupportedError(
      'Outlet tills detail is not supported by the current backend contract.',
    );
  }
}
