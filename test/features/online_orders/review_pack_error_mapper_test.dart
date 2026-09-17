import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/utils/review_pack_error_mapper.dart';

void main() {
  group('review_pack_error_mapper', () {
    DioException createDioException({
      int? statusCode,
      Map<String, dynamic>? data,
    }) {
      return DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: statusCode,
          data: data,
        ),
      );
    }

    test('maps online_orders.concurrency_conflict code', () {
      final error = createDioException(
        statusCode: 409,
        data: {'errorCode': 'online_orders.concurrency_conflict'},
      );
      expect(
        mapReviewPackError(error),
        'This order changed. Refresh and try again.',
      );
    });

    test('maps online_orders.not_packable code', () {
      final error = createDioException(
        statusCode: 400,
        data: {'errorCode': 'online_orders.not_packable'},
      );
      expect(
        mapReviewPackError(error),
        'This order is not eligible to pack yet.',
      );
    });

    test('maps online_orders.not_readyable code', () {
      final error = createDioException(
        statusCode: 400,
        data: {'errorCode': 'online_orders.not_readyable'},
      );
      expect(
        mapReviewPackError(error),
        'This order must be packed before it can be marked ready.',
      );
    });

    test('maps online_orders.permission_denied code', () {
      final error = createDioException(
        statusCode: 403,
        data: {'errorCode': 'online_orders.permission_denied'},
      );
      expect(
        mapReviewPackError(error),
        'You do not have permission for this action.',
      );
    });

    test('maps online_orders.invalid_packing_note code', () {
      final error = createDioException(
        statusCode: 400,
        data: {'errorCode': 'online_orders.invalid_packing_note'},
      );
      expect(
        mapReviewPackError(error),
        'Packing note is invalid.',
      );
    });

    test('maps HTTP 409 without code to concurrency conflict message', () {
      final error = createDioException(statusCode: 409);
      expect(
        mapReviewPackError(error),
        'This order changed. Refresh and try again.',
      );
    });

    test('maps generic status code to default error message', () {
      final error = createDioException(statusCode: 500);
      expect(
        mapReviewPackError(error),
        'Unable to mark this order ready for collection.',
      );
    });

    test('mapReviewPackException handles DioException', () {
      final error = createDioException(
        statusCode: 400,
        data: {'errorCode': 'online_orders.invalid_packing_note'},
      );
      expect(
        mapReviewPackException(error),
        'Packing note is invalid.',
      );
    });

    test('mapReviewPackException handles arbitrary exception with fallback', () {
      expect(
        mapReviewPackException(Exception('Network disconnected')),
        'Unable to mark this order ready for collection.',
      );
    });
  });
}
