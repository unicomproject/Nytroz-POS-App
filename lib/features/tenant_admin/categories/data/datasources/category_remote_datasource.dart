import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../domain/entities/category_list_query.dart';
import '../models/category_dto.dart';

class CategoryRemoteDatasource {
  const CategoryRemoteDatasource(this._dio);

  final Dio _dio;

  static const _categoriesPath = '/api/v1/categories';
  static const _tenantAdminCategoriesPath = '/api/v1/tenant-admin/categories';

  Future<CategoryListResultDto> getCategories(CategoryListQuery query) async {
    final response = await _dio.get<dynamic>(
      _categoriesPath,
      queryParameters: {
        'pageNumber': query.pageNumber,
        'pageSize': query.pageSize,
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.statusValue != null) 'status': query.statusValue,
        if (query.rootOnly) 'rootOnly': true,
        if (query.parentCategoryId != null)
          'parentCategoryId': query.parentCategoryId,
      },
    );

    return CategoryListResultDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<CategoryTreeResultDto> getCategoryTree() async {
    final response = await _dio.get<dynamic>('$_categoriesPath/tree');

    return CategoryTreeResultDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<CategoryDto> getCategoryById(String id) async {
    final response = await _dio.get<dynamic>('$_categoriesPath/$id');

    return CategoryDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<CategoryDto> createCategory(CategoryUpsertRequestDto request) async {
    final response = await _dio.post<dynamic>(
      _categoriesPath,
      data: request.toJson(),
    );

    return CategoryDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<CategoryDto> updateCategory(
    String id,
    CategoryUpsertRequestDto request,
  ) async {
    final response = await _dio.put<dynamic>(
      '$_categoriesPath/$id',
      data: request.toJson(),
    );

    return CategoryDto.fromJson(
      _unwrapApiPayload(response.data, response.requestOptions),
    );
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete<dynamic>('$_categoriesPath/$id');
  }

  Future<void> uploadCategoryImage(
    String id,
    Uint8List bytes,
    String fileName,
  ) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    await _dio.post<dynamic>(
      '$_tenantAdminCategoriesPath/$id/image',
      data: formData,
    );
  }

  Future<void> removeCategoryImage(String id) async {
    await _dio.delete<dynamic>(
      '$_tenantAdminCategoriesPath/$id/image',
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
      return Map<String, dynamic>.from(root['data'] as Map);
    }

    return root;
  }
}
