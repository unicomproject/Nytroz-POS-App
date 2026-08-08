import 'tenant_product_create_options.dart';

class TenantProductFilterOptions {
  const TenantProductFilterOptions({
    required this.categories,
    required this.brands,
    required this.productStatuses,
    required this.stockStatuses,
  });

  final List<ProductCategoryOption> categories;
  final List<ProductBrandOption> brands;
  final List<String> productStatuses;
  final List<String> stockStatuses;
}
