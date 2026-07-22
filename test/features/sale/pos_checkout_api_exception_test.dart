import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_api_exception.dart';

void main() {
  group('checkoutApiExceptionFromDio', () {
    test('uses backend validation message without network fallback', () {
      final error = DioException(
        requestOptions:
            RequestOptions(path: '/api/v1/pos/checkout/start-payment'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions:
              RequestOptions(path: '/api/v1/pos/checkout/start-payment'),
          statusCode: 400,
          data: const {
            'success': false,
            'message':
                'Cash received must be greater than or equal to the sale total.',
            'errorCode': 'VALIDATION_FAILED',
          },
        ),
      );

      final exception = checkoutApiExceptionFromDio(error);

      expect(exception.message,
          'Cash received must be greater than or equal to the sale total.');
      expect(exception.statusCode, 400);
      expect(exception.isNetworkUnavailable, isFalse);
    });

    test('does not treat backend 500 response as network fallback', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/pos/checkout/summary'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/pos/checkout/summary'),
          statusCode: 500,
          data: const {
            'success': false,
            'message': 'Unexpected server error.',
            'errorCode': 'SERVER_ERROR',
          },
        ),
      );

      final exception = checkoutApiExceptionFromDio(error);

      expect(exception.message, 'Unexpected server error.');
      expect(exception.statusCode, 500);
      expect(exception.isNetworkUnavailable, isFalse);
    });

    test('preserves backend checkout error code for recovery actions', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/pos/checkout/summary'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/pos/checkout/summary'),
          statusCode: 409,
          data: const {
            'code': 'pos_checkout.discount_application_expired',
            'message': 'The approved discount has expired.',
          },
        ),
      );

      final exception = checkoutApiExceptionFromDio(error);

      expect(exception.code, 'pos_checkout.discount_application_expired');
      expect(exception.message, 'The approved discount has expired.');
    });

    test('uses validation problem errors when backend omits message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/pos/checkout/summary'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/pos/checkout/summary'),
          statusCode: 400,
          data: const {
            'title': 'One or more validation errors occurred.',
            'errors': {
              r'$.lines[0].variantId': [
                'The JSON value could not be converted to System.Guid.'
              ],
            },
          },
        ),
      );

      final exception = checkoutApiExceptionFromDio(error);

      expect(
        exception.message,
        'The JSON value could not be converted to System.Guid.',
      );
      expect(exception.statusCode, 400);
      expect(exception.isNetworkUnavailable, isFalse);
    });

    test('treats connection error without response as network fallback', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/pos/checkout/summary'),
        type: DioExceptionType.connectionError,
        message: 'Connection refused',
      );

      final exception = checkoutApiExceptionFromDio(error);

      expect(exception.isNetworkUnavailable, isTrue);
    });
  });
}
