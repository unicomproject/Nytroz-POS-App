import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/network/dio_client.dart';
import 'core/network/dio_provider.dart';
import 'flavors/development/tenant_admin_dev_api_interceptor.dart';

void main() {
  const useDevApiFallback = bool.fromEnvironment(
    'USE_DEV_API_FALLBACK',
    defaultValue: false,
  );

  final dio = buildAppDio(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5050',
    ),
    interceptors: [
      if (useDevApiFallback) TenantAdminDevApiInterceptor(),
    ],
  );

  runApp(
    ProviderScope(
      overrides: [
        appDioProvider.overrideWithValue(dio),
      ],
      child: const NytrozPosApp(),
    ),
  );
}
