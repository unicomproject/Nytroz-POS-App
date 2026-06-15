import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/tenant_admin_access_checker.dart';
import 'tenant_admin_context_provider.dart';

final tenantAdminAccessCheckerProvider =
    FutureProvider<TenantAdminAccessChecker>((ref) async {
  final context = await ref.watch(tenantAdminContextProvider.future);

  return TenantAdminAccessChecker(context);
});
