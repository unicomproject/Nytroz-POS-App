import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/tenant_admin_access_checker.dart';
import 'tenant_admin_context_provider.dart';

final tenantAdminAccessCheckerProvider =
    Provider<AsyncValue<TenantAdminAccessChecker>>((ref) {
  final context = ref.watch(tenantAdminContextProvider);

  return context.whenData((tenantContext) {
    return TenantAdminAccessChecker(tenantContext);
  });
});
