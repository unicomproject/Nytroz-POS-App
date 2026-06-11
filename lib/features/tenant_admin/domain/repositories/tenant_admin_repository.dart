import '../entities/tenant_admin_context.dart';
import '../entities/tenant_admin_menu_item.dart';

abstract class TenantAdminRepository {
  Future<TenantAdminContext> getContext();

  Future<List<TenantAdminMenuItem>> getMenu();
}
