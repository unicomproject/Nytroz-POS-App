import 'dart:developer';
import 'package:dio/dio.dart';
import '../../../../../core/network/media_url_resolver.dart';

import '../../domain/entities/outlet_list_query.dart';
import '../../domain/entities/outlet_image_upload.dart';
import '../models/create_outlet_request_dto.dart';
import '../models/outlet_detail_dtos.dart';
import '../models/outlet_create_options_dto.dart';
import '../models/outlet_dto.dart';
import '../models/outlet_image_upload_dto.dart';
import '../models/tenant_admin_outlet_list_dto.dart';
import '../models/tenant_admin_outlet_overview_dto.dart';

class OutletRemoteDatasource {
  const OutletRemoteDatasource(this._dio);

  final Dio _dio;

  static const _outletBase = '/api/v1/outlets';
  static const _tenantAdminBase = '/api/v1/tenant-admin/outlets';

  Future<TenantAdminOutletListResponseDto> getOutlets(
      OutletListQuery query) async {
    final response = await _dio.get<dynamic>(
      _tenantAdminBase,
      queryParameters: _listQueryParameters(query),
    );

    return _parseListResponse(response.data, response.requestOptions);
  }

  Future<OutletSummaryDashboardDto> getSummary() async {
    final response = await _dio.get<dynamic>('$_outletBase/summary');
    return OutletSummaryDashboardDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
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

  Future<TenantAdminOutletOverviewDto> getTenantAdminOverview(String id) async {
    final response = await _dio.get<dynamic>('$_tenantAdminBase/$id/overview');
    return TenantAdminOutletOverviewDto.fromJson(
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
    try {
      final response = await _dio.put<dynamic>(
        '$_outletBase/$id',
        data: request.toUpdateJson(),
      );
      return OutletDetailsDto.fromJson(
        _unwrapApiPayload(response.data, response.requestOptions),
      );
    } on DioException catch (e) {
      log('UPDATE OUTLET 400 ERROR RESPONSE: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> deleteOutlet(String id) async {
    await _dio.delete<void>('$_outletBase/$id');
  }

  Future<OutletImageUploadDto> uploadOutletImage(
    OutletImageUploadInput input, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final response = await _dio.post<dynamic>(
      '$_outletBase/image-uploads',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          input.bytes,
          filename: input.fileName,
          contentType: DioMediaType.parse(input.mimeType),
        ),
      }),
      onSendProgress: onProgress,
    );
    return OutletImageUploadDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<void> deleteStagedOutletImage(String mediaAssetId) {
    return _dio.delete<void>('$_outletBase/image-uploads/$mediaAssetId');
  }

  Future<void> updateOutletStatus(String id, String status) async {
    // PUT request to update lifecycle status (ACTIVE / INACTIVE)
    final response = await _dio.put<void>(
      '$_tenantAdminBase/$id/status',
      data: {"status": status},
    );
    // No content expected; throw on error via DioException handling
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        message: 'Failed to update outlet status',
      );
    }
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
      if (query.status != null) 'status': query.status,
      if (query.outletType != null) 'outletType': query.outletType,
      if (query.sortBy.isNotEmpty) 'sortBy': query.sortBy,
      if (query.sortDirection.isNotEmpty) 'sortDirection': query.sortDirection,
    };
  }

  TenantAdminOutletListResponseDto _parseListResponse(
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

      _resolvePayloadMediaUrls(payload);

      return TenantAdminOutletListResponseDto.fromJson(payload);
    }

    return const TenantAdminOutletListResponseDto(
      items: [],
      pageNumber: 1,
      pageSize: 20,
      totalCount: 0,
    );
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
      final payload = Map<String, dynamic>.from(root['data'] as Map);
      _resolvePayloadMediaUrls(payload);
      return payload;
    }

    _resolvePayloadMediaUrls(root);
    return root;
  }

  void _resolvePayloadMediaUrls(Map<String, dynamic> payload) {
    void resolve(Map map, String key) {
      if (map[key] != null) {
        map[key] = MediaUrlResolver.resolve(
          map[key]?.toString(),
          apiBaseUrl: _dio.options.baseUrl,
        ) ?? map[key];
      }
    }

    if (payload['items'] is List) {
      for (final item in payload['items']) {
        if (item is Map) {
          resolve(item, 'imageUrl');
          if (item['manager'] is Map) {
            resolve(item['manager'], 'avatarUrl');
          }
        }
      }
    }

    if (payload['outlet'] is Map) {
      resolve(payload['outlet'], 'imageUrl');
    }
    if (payload['manager'] is Map) {
      resolve(payload['manager'], 'avatarUrl');
    }

    resolve(payload, 'imageUrl');
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
