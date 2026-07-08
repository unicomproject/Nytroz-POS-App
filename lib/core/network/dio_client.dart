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
          developer.log(
            'API base URL unreachable. baseUrl=${dio.options.baseUrl} '
            'uri=${error.requestOptions.uri} type=${error.type.name} '
            'message=${error.message}',
            name: 'api.network',
            error: error.error,
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
