import 'package:dio/dio.dart';

class AuthUnauthorizedInterceptor extends Interceptor {
  AuthUnauthorizedInterceptor({
    required Dio dio,
    required Future<String?> Function() refreshAccessToken,
    required Future<void> Function() onRefreshRejected,
  })  : _dio = dio,
        _refreshAccessToken = refreshAccessToken,
        _onRefreshRejected = onRefreshRejected;

  static const _retryMarker = 'tenantAuthRefreshRetried';
  final Dio _dio;
  final Future<String?> Function() _refreshAccessToken;
  final Future<void> Function() _onRefreshRejected;
  Future<String?>? _refreshInFlight;

  static bool isAuthRequest(RequestOptions options) {
    final path = options.path.toLowerCase();
    return path.contains('/tenant-auth/login') ||
        path.contains('/tenant-auth/refresh') ||
        path.contains('/tenant-auth/logout') ||
        path.contains('/auth/');
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        isAuthRequest(request) ||
        request.extra[_retryMarker] == true) {
      handler.next(err);
      return;
    }

    String? accessToken;
    try {
      accessToken = await (_refreshInFlight ??= _runRefresh());
    } on DioException catch (refreshError) {
      if (_isAuthenticationRejection(refreshError.response?.statusCode)) {
        await _onRefreshRejected();
      }
      handler.next(err);
      return;
    } catch (_) {
      handler.next(err);
      return;
    }

    if (accessToken == null || accessToken.isEmpty) {
      await _onRefreshRejected();
      handler.next(err);
      return;
    }

    try {
      final response = await _dio.fetch<dynamic>(request.copyWith(
        headers: {
          ...request.headers,
          'Authorization': 'Bearer $accessToken',
        },
        extra: {...request.extra, _retryMarker: true},
      ));
      handler.resolve(response);
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401) {
        await _onRefreshRejected();
      }
      handler.reject(retryError);
    }
  }

  Future<String?> _runRefresh() async {
    try {
      return await _refreshAccessToken();
    } finally {
      _refreshInFlight = null;
    }
  }

  bool _isAuthenticationRejection(int? statusCode) =>
      statusCode == 400 || statusCode == 401 || statusCode == 403;
}
