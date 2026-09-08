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

  late final String apiBaseUrl;
  try {
    apiBaseUrl = await resolveApiBaseUrl();
  } on ApiConfigurationException catch (error, stackTrace) {
    developer.log(
      error.message,
      name: 'api.config',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
  final resolvedUri = Uri.parse(apiBaseUrl);
  final safeOrigin = resolvedUri.replace(
    userInfo: '',
    path: '',
    query: '',
    fragment: '',
  );
  developer.log(
    'API base URL resolved. origin=$safeOrigin',
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
