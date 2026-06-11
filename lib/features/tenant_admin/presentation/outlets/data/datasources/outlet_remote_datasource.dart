import 'package:dio/dio.dart';

import '../models/create_outlet_request_dto.dart';
import '../models/outlet_dto.dart';

class OutletRemoteDatasource {
  const OutletRemoteDatasource(this._dio);

  final Dio _dio;

  Future<OutletListResultDto> getOutlets({String? search}) async {
    final response = await _dio.get<dynamic>(
      '/api/tenant-admin/outlets',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final data = response.data;

    if (data is List) {
      return OutletListResultDto.fromArray(data);
    }

    if (data is Map) {
      return OutletListResultDto.fromJson(Map<String, dynamic>.from(data));
    }

    return OutletListResultDto.fromArray(const []);
  }

  Future<OutletDetailsDto> getOutletDetails(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/tenant-admin/outlets/$id',
    );

    return OutletDetailsDto.fromJson(response.data ?? const {});
  }

  Future<OutletDetailsDto> createOutlet(CreateOutletRequestDto request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/tenant-admin/outlets',
      data: request.toJson(),
    );

    return OutletDetailsDto.fromJson(response.data ?? const {});
  }

  Future<OutletDetailsDto> updateOutlet(
    String id,
    CreateOutletRequestDto request,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/tenant-admin/outlets/$id',
      data: request.toJson(),
    );

    return OutletDetailsDto.fromJson(response.data ?? const {});
  }

  Future<void> updateOutletStatus(String id, String status) async {
    await _dio.patch<void>(
      '/api/tenant-admin/outlets/$id/status',
      data: {'status': status},
    );
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
}
