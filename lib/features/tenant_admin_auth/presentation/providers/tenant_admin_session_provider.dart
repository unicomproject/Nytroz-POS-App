import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tenant_admin_session.dart';

class TenantAdminSessionNotifier extends StateNotifier<TenantAdminSession?> {
  TenantAdminSessionNotifier() : super(null);

  void setSession(TenantAdminSession session) {
    state = session;
  }

  void clear() {
    state = null;
  }
}

final tenantAdminSessionProvider =
    StateNotifierProvider<TenantAdminSessionNotifier, TenantAdminSession?>(
  (ref) => TenantAdminSessionNotifier(),
);
