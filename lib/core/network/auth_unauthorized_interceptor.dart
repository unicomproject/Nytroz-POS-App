import 'package:dio/dio.dart';

class AuthUnauthorizedInterceptor extends Interceptor {
  AuthUnauthorizedInterceptor(this._onUnauthorized);

  final Future<void> Function() _onUnauthorized;

  static bool isAuthRequest(RequestOptions options) {
    final path = options.path.toLowerCase();
    return path.contains('/auth/');
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !isAuthRequest(err.requestOptions)) {
      await _onUnauthorized();
    }

    handler.next(err);
  }
}
