import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../domain/entities/product.dart';
import '../models/create_product_request_dto.dart';
import '../models/product_dto.dart';

class ProductRemoteDatasource {
  const ProductRemoteDatasource(this._dio);

  final Dio _dio;

  static const _productPath = '/api/v1/tenant-admin/products';

  Future<ProductListResultDto> getProducts(ProductListQuery query) async {
    final response = await _dio.get<dynamic>(
      _productPath,
      queryParameters: _listQueryParameters(query),
    );

    return _parseListResponse(response.data, response.requestOptions);
  }

  Future<CreatedProductDto> createProduct(CreateProductRequestDto request) async {
    final response = await _dio.post<dynamic>(
      _productPath,
      data: request.toJson(),
    );

    return CreatedProductDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<void> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await _dio.post<dynamic>(
      '$_productPath/$productId/image',
      data: formData,
    );

    if (response.data is Map && (response.data as Map)['success'] == false) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: (response.data as Map)['message']?.toString(),
      );
    }
  }

  Map<String, dynamic> _listQueryParameters(ProductListQuery query) {
    return {
      'page': query.page,
      'pageSize': query.pageSize,
      if (query.search != null && query.search!.trim().isNotEmpty)
        'search': query.search!.trim(),
      if (query.status != null && query.status!.trim().isNotEmpty)
        'status': query.status!.trim(),
    };
  }

  ProductListResultDto _parseListResponse(
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

      return ProductListResultDto.fromJson(payload);
    }

    return ProductListResultDto.fromJson(const {});
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
