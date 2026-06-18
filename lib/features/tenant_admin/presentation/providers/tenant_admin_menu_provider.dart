import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../application/usecases/get_tenant_admin_menu.dart';
import '../../domain/entities/tenant_admin_menu_item.dart';
import '../../domain/errors/tenant_admin_context_exception.dart';
import 'tenant_admin_access_provider.dart';
import 'tenant_admin_context_provider.dart';

final getTenantAdminMenuProvider = Provider<GetTenantAdminMenu>((ref) {
  return GetTenantAdminMenu(ref.watch(tenantAdminRepositoryProvider));
});

final tenantAdminMenuProvider =
    FutureProvider<List<TenantAdminMenuItem>>((ref) async {
  ref.watch(authHeaderSyncProvider);

  final session = ref.watch(authSessionProvider);
  if (session == null || !session.isAuthenticated) {
    return const [];
  }

  try {
    final accessChecker =
        await ref.watch(tenantAdminAccessCheckerProvider.future);
    final menu = await ref.watch(getTenantAdminMenuProvider).call();

    return menu.where(accessChecker.canAccessMenuItem).toList(growable: false)
      ..sort((first, second) => first.order.compareTo(second.order));
  } on TenantAdminContextException {
    rethrow;
  }
});
