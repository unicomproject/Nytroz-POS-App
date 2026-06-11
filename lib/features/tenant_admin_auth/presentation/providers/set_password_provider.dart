import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/set_tenant_admin_password.dart';
import 'tenant_payment_provider.dart';

final setTenantAdminPasswordProvider = Provider<SetTenantAdminPassword>((ref) {
  return SetTenantAdminPassword(ref.watch(tenantAdminAuthRepositoryProvider));
});
