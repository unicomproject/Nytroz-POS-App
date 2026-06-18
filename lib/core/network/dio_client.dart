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

  dio.interceptors.addAll(interceptors);
  return dio;
}
