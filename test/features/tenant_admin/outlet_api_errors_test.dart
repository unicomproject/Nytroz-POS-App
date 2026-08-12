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

    test('maps location contact and image fields to Step 2', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/outlets'),
        response: Response(
            requestOptions: RequestOptions(path: '/api/v1/outlets'),
            data: const {
              'details': [
                {
                  'field': 'address.contactEmail',
                  'message': 'Email is invalid.'
                },
                {'field': 'imageMediaAssetId', 'message': 'Image is invalid.'},
              ],
            }),
      );
      final fields = outletValidationErrors(error);
      expect(fields['contactEmail'], 'Email is invalid.');
      expect(fields['outletImage'], 'Image is invalid.');
      expect(outletErrorStep(fields), 1);
    });

    test('maps timezone validation to location step', () {
      expect(
        outletErrorStep(const {
          'timezone': 'Timezone is required.',
        }),
        1,
      );
    });

    test('maps backend timezone field alias', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/outlets'),
        response: Response(
          requestOptions: RequestOptions(path: '/outlets'),
          data: {
            'errors': {
              'timezone': ['The Timezone field is required.'],
            },
          },
        ),
      );

      final fieldErrors = outletValidationErrors(error);

      expect(fieldErrors['timezone'], 'The Timezone field is required.');
    });

    test('maps backend OutletName field alias', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/outlets'),
        response: Response(
          requestOptions: RequestOptions(path: '/outlets'),
          data: {
            'errors': {
              'OutletName': ['The OutletName field is required.'],
            },
          },
        ),
      );

      final fieldErrors = outletValidationErrors(error);

      expect(fieldErrors['outletName'], 'The OutletName field is required.');
    });

    test('maps top-level outlet name message to field error', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/outlets'),
        response: Response(
          requestOptions: RequestOptions(path: '/outlets'),
          data: const {
            'message': 'The OutletName field is required.',
          },
        ),
      );

      final fieldErrors = outletValidationErrors(error);

      expect(fieldErrors['outletName'], 'The OutletName field is required.');
    });

    test('maps top-level timezone message to field error', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/outlets'),
        response: Response(
          requestOptions: RequestOptions(path: '/outlets'),
          data: const {
            'message': 'The Timezone field is required.',
          },
        ),
      );

      final fieldErrors = outletValidationErrors(error);

      expect(fieldErrors['timezone'], 'The Timezone field is required.');
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
