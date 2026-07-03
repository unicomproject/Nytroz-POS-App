import 'dart:typed_data';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../mappers/product_mapper.dart';
import '../models/create_product_request_dto.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remoteDatasource);

  final ProductRemoteDatasource _remoteDatasource;

  @override
  Future<ProductListResult> getProducts(ProductListQuery query) async {
    final result = await _remoteDatasource.getProducts(query);
    return ProductMapper.toListResult(result);
  }

  @override
  Future<CreatedProduct> createProduct(ProductFormData data) async {
    final request = CreateProductRequestDto.fromForm(data);
    final result = await _remoteDatasource.createProduct(request);
    return ProductMapper.toCreatedEntity(result);
  }

  @override
  Future<void> uploadProductImage({
    required String productId,
    required List<int> bytes,
    required String fileName,
  }) {
    return _remoteDatasource.uploadProductImage(
      productId: productId,
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
    );
  }
}
