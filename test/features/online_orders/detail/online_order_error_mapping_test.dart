import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';

void main() {
  group('online order error mapping', () {
    test('maps backend conflict codes to a production-safe message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/online-orders'),
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/online-orders'),
          statusCode: 409,
          data: const {
            'code': 'online_orders.fulfilment_conflict',
            'message': 'internal detail that must not be rendered',
          },
        ),
      );

      final message = onlineOrderErrorMessage(error);
      expect(message, contains('changed'));
      expect(message, isNot(contains('internal detail')));
    });

    test('maps outlet access denial to an actionable safe message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/online-orders'),
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/online-orders'),
          statusCode: 403,
          data: const {
            'code': 'online_orders.outlet_access_denied',
            'message': 'internal authorization detail',
          },
        ),
      );

      final message = onlineOrderErrorMessage(error);
      expect(message, contains('access to this outlet'));
      expect(message, contains('administrator'));
      expect(message, isNot(contains('internal authorization detail')));
    });
  });
}
