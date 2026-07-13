import '../../domain/entities/product_dashboard.dart';
import '../../domain/repositories/product_dashboard_repository.dart';
import '../datasources/product_dashboard_remote_datasource.dart';
import '../mappers/product_dashboard_mapper.dart';

class ProductDashboardRepositoryImpl implements ProductDashboardRepository {
  const ProductDashboardRepositoryImpl(this._remoteDatasource);

  final ProductDashboardRemoteDatasource _remoteDatasource;

  @override
  Future<ProductDashboard> getDashboard({
    required ProductDashboardQuery query,
  }) async {
    final dto = await _remoteDatasource.getDashboard(query);
    return ProductDashboardMapper.toEntity(dto);
  }
}
