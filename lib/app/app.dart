import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/pos_theme_provider.dart';
import '../features/auth/presentation/providers/auth_network_provider.dart';
import '../features/auth/presentation/providers/session_provider.dart';
import '../features/sale/presentation/providers/completed_sale_print_provider.dart';
import '../features/tenant_admin/presentation/providers/tenant_admin_session_sync_provider.dart';
import '../features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../shared/pos_session/pos_session_bootstrap_provider.dart';
import 'nytroz_scroll_behavior.dart';
import 'router/app_router.dart';

class NytrozPosApp extends ConsumerStatefulWidget {
  const NytrozPosApp({super.key});

  @override
  ConsumerState<NytrozPosApp> createState() => _NytrozPosAppState();
}

class _NytrozPosAppState extends ConsumerState<NytrozPosApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(completedSalePrintProvider.notifier).recoverPendingOperations();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authHeaderSyncProvider);
    ref.watch(authNetworkGuardProvider);
    ref.watch(tenantAdminSessionSyncProvider);
    ref.watch(posSessionBootstrapProvider);
    ref.watch(completedSalePrintProvider);
    final router = ref.watch(appRouterProvider);
    final posTheme = ref.watch(posThemeProvider);

    return MaterialApp.router(
      title: 'Nytroz POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: posTheme.primary).copyWith(
          primary: posTheme.primary,
          secondary: posTheme.secondary,
        ),
        scaffoldBackgroundColor: TenantAdminColors.background,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      scrollBehavior: const NytrozScrollBehavior(),
      routerConfig: router,
    );
  }
}
