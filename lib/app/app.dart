import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/tenant_admin/presentation/providers/tenant_admin_session_sync_provider.dart';
import '../features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../features/auth/presentation/providers/auth_network_provider.dart';
import '../features/auth/presentation/providers/session_provider.dart';
import '../shared/pos_session/pos_session_bootstrap_provider.dart';
import 'router/app_router.dart';

class NytrozPosApp extends ConsumerWidget {
  const NytrozPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authHeaderSyncProvider);
    ref.watch(authNetworkGuardProvider);
    ref.watch(tenantAdminSessionSyncProvider);
    ref.watch(posSessionBootstrapProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Nytroz POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: TenantAdminColors.primary,
        ),
        scaffoldBackgroundColor: TenantAdminColors.background,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
