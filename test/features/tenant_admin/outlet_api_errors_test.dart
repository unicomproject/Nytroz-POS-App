import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/utils/outlet_api_errors.dart';

void main() {
  group('outlet_api_errors', () {
    test('maps backend field names to form field keys', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/outlets'),
        response: Response(
          requestOptions: RequestOptions(path: '/outlets'),
          data: {
            'errors': {
              'email': ['Email is invalid.'],
              'name': ['Name is required.'],
            },
          },
        ),
      );

      final fieldErrors = outletValidationErrors(error);

      expect(fieldErrors['emailAddress'], 'Email is invalid.');
      expect(fieldErrors['outletName'], 'Name is required.');
    });

    test('returns first field error for submit message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/outlets'),
        response: Response(
          requestOptions: RequestOptions(path: '/outlets'),
          data: const {'message': 'Validation failed'},
        ),
      );

      final message = outletSubmitErrorMessage(
        error,
        const {'emailAddress': 'Email is invalid.'},
      );

      expect(message, 'Email is invalid.');
    });

    test('returns earliest wizard step for field errors', () {
      expect(
        outletErrorStep(const {
          'city': 'City is required.',
          'outletName': 'Name is required.',
        }),
        0,
      );
    });
  });
}
