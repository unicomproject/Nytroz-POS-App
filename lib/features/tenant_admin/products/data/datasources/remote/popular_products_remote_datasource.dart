import 'package:dio/dio.dart';

import '../../../domain/entities/curated_popular_product.dart';

class PopularProductsRemoteDatasource {
  const PopularProductsRemoteDatasource(this._dio);

  final Dio _dio;

  static const _path = '/api/v1/collections/pos-popular/products';

  Future<List<CuratedPopularProduct>> list() async {
    final response = await _dio.get<dynamic>(_path);
    return _parse(response.data);
  }

  Future<List<CuratedPopularProduct>> replace(List<String> productIds) async {
    final response = await _dio.put<dynamic>(_path, data: productIds);
    return _parse(response.data);
  }

  List<CuratedPopularProduct> _parse(dynamic data) {
    List<dynamic> list = [];
    if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else if (data is List) {
      list = data;
    }
    return list
        .map((item) => CuratedPopularProduct.fromJson(
            Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
