import 'package:dio/dio.dart';

import '../../domain/entities/brand_list_query.dart';
import '../models/brand_dto.dart';

class BrandRemoteDatasource {
  const BrandRemoteDatasource(this._dio);

  final Dio _dio;

  static const _brandsPath = '/api/v1/brands';

  Future<BrandListResultDto> listBrands(BrandListQuery query) async {
    final response = await _dio.get<dynamic>(
      _brandsPath,
      queryParameters: {
        'pageNumber': query.pageNumber,
        'pageSize': query.pageSize,
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
      },
    );

    return BrandListResultDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<BrandDto> getBrandById(String id) async {
    final response = await _dio.get<dynamic>('$_brandsPath/$id');

    return BrandDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<BrandDto> createBrand(BrandUpsertRequestDto request) async {
    final response = await _dio.post<dynamic>(
      _brandsPath,
      data: request.toJson(),
    );

    return BrandDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<BrandDto> updateBrand(String id, BrandUpsertRequestDto request) async {
    final response = await _dio.put<dynamic>(
      '$_brandsPath/$id',
      data: request.toJson(),
    );

    return BrandDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<void> deleteBrand(String id) async {
    await _dio.delete<dynamic>('$_brandsPath/$id');
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
