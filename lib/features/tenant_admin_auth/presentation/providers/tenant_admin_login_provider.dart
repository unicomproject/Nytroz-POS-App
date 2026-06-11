import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/login_tenant_admin.dart';
import 'tenant_payment_provider.dart';

final loginTenantAdminProvider = Provider<LoginTenantAdmin>((ref) {
  return LoginTenantAdmin(ref.watch(tenantAdminAuthRepositoryProvider));
});
