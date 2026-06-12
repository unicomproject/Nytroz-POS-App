import '../../domain/entities/tenant_admin_context.dart';
import '../../domain/repositories/tenant_admin_repository.dart';

class GetTenantAdminContext {
  const GetTenantAdminContext(this._repository);

  final TenantAdminRepository _repository;

  Future<TenantAdminContext> call() {
    return _repository.getContext();
  }
}
