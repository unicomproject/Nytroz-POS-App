import 'dart:developer' as developer;

import 'package:dio/dio.dart';

Dio buildAppDio({
  required String baseUrl,
  Iterable<Interceptor> interceptors = const [],
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        if (_isNetworkFailure(error)) {
          final requestUri = error.requestOptions.uri;
          final safeRequestUri = requestUri.replace(
            userInfo: '',
            query: '',
            fragment: '',
          );
          developer.log(
            'API request unreachable. uri=$safeRequestUri '
            'type=${error.type.name}',
            name: 'api.network',
          );
        }
        handler.next(error);
      },
    ),
  );
  dio.interceptors.addAll(interceptors);
  return dio;
}

bool _isNetworkFailure(DioException error) {
  return error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.unknown;
}
