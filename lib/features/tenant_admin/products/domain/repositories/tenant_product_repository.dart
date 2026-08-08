import '../../domain/entities/product_form_data.dart';
import '../../domain/entities/tenant_product.dart';
import '../../domain/entities/tenant_product_create_options.dart';
import '../../domain/entities/tenant_product_filter_options.dart';
import '../../domain/entities/product_delete_result.dart';
import '../../domain/entities/product_status_update_result.dart';
import '../../domain/entities/tenant_product_detail.dart';

abstract class TenantProductRepository {
  Future<TenantProductListResult> getProducts({
    required TenantProductListQuery query,
  });

  Future<TenantProductSummary> getProductSummary();
  Future<TenantProductCreateOptions> getCreateOptions();
  Future<TenantProductDetail> getProductById(String productId);
  Future<ProductCreateResult> createProduct(ProductFormData request);
  Future<TenantProductDetail> updateProduct(
    String productId,
    ProductFormData request,
  );
  Future<ProductStatusUpdateResult> updateProductStatus(
    String productId,
    String status,
  );
  Future<ProductDeleteResult> deleteProduct(String productId);
  Future<TenantProductFilterOptions> getProductFilterOptions();
}
