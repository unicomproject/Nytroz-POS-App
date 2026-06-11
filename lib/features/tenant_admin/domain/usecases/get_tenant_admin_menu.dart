import '../entities/tenant_admin_menu_item.dart';
import '../repositories/tenant_admin_repository.dart';

class GetTenantAdminMenu {
  const GetTenantAdminMenu(this._repository);

  final TenantAdminRepository _repository;

  Future<List<TenantAdminMenuItem>> call() {
    return _repository.getMenu();
  }
}
