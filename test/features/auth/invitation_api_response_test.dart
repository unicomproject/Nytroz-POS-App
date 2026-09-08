import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:nytroz_pos/features/auth/data/models/set_password_request_dto.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_exception.dart';

void main() {
  const request = SetPasswordRequestDto(setupToken: 'test-only',
      password: 'Password1', confirmPassword: 'Password1');
  for (final success in [true, false, null]) {
    test('activation requires explicit backend success: $success', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response(requestOptions: options,
            statusCode: 200, data: {'success': success}));
      }));
      final operation = AuthRemoteDatasource(dio).setPassword(request);
      if (success == true) {
        await operation;
      } else {
        await expectLater(operation, throwsA(isA<AuthException>()));
      }
      dio.close();
    });
  }
  for (final status in [null, 503]) {
    test('validation distinguishes network and server error: $status', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.reject(DioException(requestOptions: options,
          type: status == null ? DioExceptionType.connectionError : DioExceptionType.badResponse,
          response: status == null ? null : Response(requestOptions: options, statusCode: status)));
      }));
      await expectLater(AuthRemoteDatasource(dio).validateSetupToken('test-only'),
        throwsA(isA<AuthException>().having((e) => e.errorCode, 'code',
            status == null ? 'NETWORK_ERROR' : 'SERVER_ERROR')));
      dio.close();
    });
  }
}
