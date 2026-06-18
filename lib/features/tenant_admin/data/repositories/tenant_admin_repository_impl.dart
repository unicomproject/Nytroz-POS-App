import '../../domain/entities/tenant_admin_context.dart';
import '../../domain/entities/tenant_admin_menu_item.dart';
import '../../domain/repositories/tenant_admin_repository.dart';
import '../catalog/tenant_admin_menu_catalog.dart';
import '../datasources/tenant_admin_remote_datasource.dart';
import '../mappers/tenant_admin_context_mapper.dart';
import '../mappers/tenant_admin_menu_mapper.dart';

class TenantAdminRepositoryImpl implements TenantAdminRepository {
  const TenantAdminRepositoryImpl(this._remoteDatasource);

  final TenantAdminRemoteDatasource _remoteDatasource;

  @override
  Future<TenantAdminContext> getContext() async {
    final dto = await _remoteDatasource.getContext();
    return dto.toEntity();
  }

  @override
  Future<List<TenantAdminMenuItem>> getMenu() async {
    final remoteItems = await _remoteDatasource.getMenu();

    if (remoteItems.isNotEmpty) {
      return remoteItems
          .map((item) => item.toEntity())
          .where((item) => item.visible)
          .toList(growable: false)
        ..sort((first, second) => first.order.compareTo(second.order));
    }

    return List<TenantAdminMenuItem>.from(tenantAdminMenuCatalog);
  }
}
