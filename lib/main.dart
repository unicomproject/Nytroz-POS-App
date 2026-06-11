import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dev/tenant_admin_dev_api_interceptor.dart';
import 'features/tenant_admin/presentation/providers/tenant_admin_context_provider.dart';
import 'features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'features/tenant_admin/tenant_admin_router.dart';
import 'features/tenant_admin_auth/presentation/providers/tenant_admin_session_provider.dart';
import 'features/tenant_admin_auth/tenant_admin_auth_router.dart';

void main() {
  final dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:5000',
      ),
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  const useDevApiFallback = bool.fromEnvironment(
    'USE_DEV_API_FALLBACK',
    defaultValue: true,
  );

  if (useDevApiFallback) {
    dio.interceptors.add(TenantAdminDevApiInterceptor());
  }

  runApp(
    ProviderScope(
      overrides: [
        tenantAdminDioProvider.overrideWithValue(dio),
      ],
      child: const NytrozPosApp(),
    ),
  );
}

class NytrozPosApp extends ConsumerWidget {
  const NytrozPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tenantAdminSessionProvider);
    final router = GoRouter(
      initialLocation: '/tenant-admin/login',
      routes: [
        ...tenantAdminAuthRoutes(),
        ...tenantAdminRoutes(),
      ],
      redirect: (context, state) {
        final path = state.uri.path;
        final isAuthRoute = path == '/tenant-admin/login' ||
            path.startsWith('/tenant-admin/payment') ||
            path.startsWith('/tenant-admin/setup');
        final isTenantAdminRoute = path.startsWith('/tenant-admin');

        if (isTenantAdminRoute && !isAuthRoute && session == null) {
          return '/tenant-admin/login';
        }

        if (path == '/tenant-admin/login' && session != null) {
          return '/tenant-admin/dashboard';
        }

        return null;
      },
    );

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
