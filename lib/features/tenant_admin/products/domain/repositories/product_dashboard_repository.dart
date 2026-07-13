import '../../domain/entities/product_dashboard.dart';

abstract class ProductDashboardRepository {
  Future<ProductDashboard> getDashboard({
    required ProductDashboardQuery query,
  });
}
