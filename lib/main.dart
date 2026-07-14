import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/network/api_config.dart';
import 'core/network/dio_client.dart';
import 'core/network/dio_provider.dart';
import 'flavors/development/tenant_admin_dev_api_interceptor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('[startup] main() executed; starting cold-start bootstrap.');
  }

  const useDevApiFallback = bool.fromEnvironment(
    'USE_DEV_API_FALLBACK',
    defaultValue: false,
  );

  final apiBaseUrl = await resolveApiBaseUrl();
  developer.log(
    'API base URL resolved. baseUrl=$apiBaseUrl',
    name: 'api.config',
  );

  final dio = buildAppDio(
    baseUrl: apiBaseUrl,
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
