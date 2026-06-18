import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import 'tenant_admin_access_provider.dart';
import 'tenant_admin_context_provider.dart';
import 'tenant_admin_menu_provider.dart';

/// Refreshes tenant-admin access state whenever the auth session changes.
final tenantAdminSessionSyncProvider = Provider<void>((ref) {
  ref.listen(authSessionProvider, (previous, next) {
    if (previous?.accessToken == next?.accessToken) {
      return;
    }

    ref.invalidate(tenantAdminContextProvider);
    ref.invalidate(tenantAdminAccessCheckerProvider);
    ref.invalidate(tenantAdminMenuProvider);
  });
});
