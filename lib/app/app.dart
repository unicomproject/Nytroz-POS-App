import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../features/auth/presentation/providers/session_provider.dart';
import 'router/app_router.dart';

class NytrozPosApp extends ConsumerWidget {
  const NytrozPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);

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
      routerConfig: createAppRouter(session),
    );
  }
}
