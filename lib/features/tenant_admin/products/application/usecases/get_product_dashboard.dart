import '../../domain/entities/product_dashboard.dart';
import '../../domain/repositories/product_dashboard_repository.dart';

class GetProductDashboard {
  const GetProductDashboard(this._repository);

  final ProductDashboardRepository _repository;

  Future<ProductDashboard> call({required ProductDashboardQuery query}) {
    return _repository.getDashboard(query: query);
  }
}
