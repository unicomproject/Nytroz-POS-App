import '../entities/product.dart';

abstract class ProductRepository {
  Future<ProductListResult> getProducts(ProductListQuery query);

  Future<CreatedProduct> createProduct(ProductFormData data);

  Future<void> uploadProductImage({
    required String productId,
    required List<int> bytes,
    required String fileName,
  });
}
