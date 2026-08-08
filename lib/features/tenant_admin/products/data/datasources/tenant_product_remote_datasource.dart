import 'package:dio/dio.dart';

import '../../domain/entities/tenant_product.dart';
import '../models/product_create_request_dto.dart';
import '../models/product_delete_response_dto.dart';
import '../models/product_status_update_dto.dart';
import '../models/tenant_product_create_options_dto.dart';
import '../models/tenant_product_detail_dto.dart';
import '../models/tenant_product_dto.dart';
import '../models/tenant_product_filter_options_dto.dart';

class TenantProductRemoteDatasource {
  const TenantProductRemoteDatasource(this._dio);

  final Dio _dio;

  static const _productsPath = '/api/v1/tenant-admin/products';
  static const _summaryPath = '/api/v1/tenant-admin/products/summary';
  static const _createOptionsPath =
      '/api/v1/tenant-admin/products/create-options';
  static const _filterOptionsPath =
      '/api/v1/tenant-admin/products/filter-options';

  Future<TenantProductFilterOptionsDto> getProductFilterOptions() async {
    final response = await _dio.get<dynamic>(_filterOptionsPath);

    return TenantProductFilterOptionsDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<TenantProductCreateOptionsDto> getCreateOptions() async {
    final response = await _dio.get<dynamic>(_createOptionsPath);

    return TenantProductCreateOptionsDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<TenantProductSummaryDto> getProductSummary() async {
    final response = await _dio.get<dynamic>(_summaryPath);

    return TenantProductSummaryDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<TenantProductListResultDto> getProducts(
    TenantProductListQuery query,
  ) async {
    final response = await _dio.get<dynamic>(
      _productsPath,
      queryParameters: _listQueryParameters(query),
    );

    return TenantProductListResultDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<TenantProductDetailDto> getProductById(String productId) async {
    final response = await _dio.get<dynamic>('$_productsPath/$productId');

    return TenantProductDetailDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<TenantProductDetailDto> updateProduct(
    String productId,
    ProductCreateRequestDto request,
  ) async {
    final response = await _dio.put<dynamic>(
      '$_productsPath/$productId',
      data: request.toJson(),
    );

    return TenantProductDetailDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<ProductCreateResponseDto> createProduct(
    ProductCreateRequestDto request,
  ) async {
    final response = await _dio.post<dynamic>(
      _productsPath,
      data: request.toJson(),
    );

    return ProductCreateResponseDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<ProductStatusUpdateResponseDto> updateProductStatus(
    String productId,
    ProductStatusUpdateRequestDto request,
  ) async {
    final response = await _dio.patch<dynamic>(
      '$_productsPath/$productId/status',
      data: request.toJson(),
    );

    return ProductStatusUpdateResponseDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<ProductDeleteResponseDto> deleteProduct(String productId) async {
    final response = await _dio.delete<dynamic>('$_productsPath/$productId');

    return ProductDeleteResponseDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Map<String, dynamic> _listQueryParameters(TenantProductListQuery query) {
    return {
      'pageNumber': query.pageNumber,
      'pageSize': query.pageSize,
      if (query.search != null && query.search!.trim().isNotEmpty)
        'search': query.search!.trim(),
      if (query.sortBy.trim().isNotEmpty)
        'sortBy': query.sortBy.trim(),
      if (query.sortDirection.trim().isNotEmpty)
        'sortDirection': query.sortDirection.trim(),
      if (query.categoryId != null && query.categoryId!.trim().isNotEmpty)
        'categoryId': query.categoryId!.trim(),
      if (query.brandId != null && query.brandId!.trim().isNotEmpty)
        'brandId': query.brandId!.trim(),
      if (query.productStatus != null && query.productStatus!.trim().isNotEmpty)
        'productStatus': query.productStatus!.trim(),
      if (query.stockStatus != null && query.stockStatus!.trim().isNotEmpty)
        'stockStatus': query.stockStatus!.trim(),
    };
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
