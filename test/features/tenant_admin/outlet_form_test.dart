import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet_details.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/utils/outlet_api_errors.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/widgets/outlet_form.dart';

void main() {
  group('OutletForm create wizard', () {
    testWidgets('blocks step 1 when required fields are missing',
        (tester) async {
      await _pumpForm(tester);

      await _tapText(tester, 'Next');
      await tester.pumpAndSettle();

      expect(find.text('Outlet Name is required.'), findsOneWidget);
      expect(find.text('Address Line 1'), findsNothing);
    });

    testWidgets('blocks step 2 when address fields are invalid',
        (tester) async {
      await _pumpForm(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Main Store');
      await _tapText(tester, 'Next');
      await tester.pumpAndSettle();

      await _tapText(tester, 'Next');
      await tester.pumpAndSettle();

      expect(find.text('Address Line 1 is required.'), findsOneWidget);
      expect(find.text('City is required.'), findsOneWidget);
      expect(find.text('Country Code is required.'), findsOneWidget);
    });

    testWidgets('blocks unsupported country codes before submit',
        (tester) async {
      var submitted = false;
      await _pumpForm(tester, onSubmit: (_) async => submitted = true);
      await tester.enterText(find.byType(TextFormField).first, 'Main Store');
      await _tapText(tester, 'Next');
      await tester.pumpAndSettle();

      await _enterField(tester, 'Address Line 1', '10 Main Street');
      await _enterField(tester, 'City', 'Colombo');
      await _enterField(tester, 'Country Code', 'ER');
      await _tapText(tester, 'Next');
      await tester.pumpAndSettle();

      expect(find.text('Country code must be one of LK, IN, GB, or US.'),
          findsOneWidget);
      expect(submitted, isFalse);
    });

    testWidgets('preserves form state when navigating back and forward',
        (tester) async {
      await _pumpForm(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Main Store');
      await _tapText(tester, 'Next');
      await tester.pumpAndSettle();
      await _tapText(tester, 'Back');
      await tester.pumpAndSettle();

      expect(find.text('Main Store'), findsOneWidget);
    });

    testWidgets('hides unsupported manager and save draft controls',
        (tester) async {
      await _pumpForm(tester);

      expect(find.text('Manager'), findsNothing);
      expect(find.text('Save draft'), findsNothing);
    });

    testWidgets('submits only once while submitting flag is true',
        (tester) async {
      var submitCount = 0;
      await _pumpForm(
        tester,
        submitting: true,
        onSubmit: (_) async => submitCount++,
      );

      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
          isFalse);
      expect(submitCount, 0);
    });

    testWidgets('renders mobile layout without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpForm(tester);

      expect(tester.takeException(), isNull);
    });

    test('maps backend details field errors to outlet form fields', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/outlets'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/outlets'),
          statusCode: 400,
          data: {
            'code': 'outlet.validation_failed',
            'message': 'Outlet validation failed.',
            'details': [
              {
                'field': 'address.countryCode',
                'message': 'Country code is not supported.',
              },
            ],
          },
        ),
      );

      final errors = outletValidationErrors(error);

      expect(errors, {'country': 'Country code is not supported.'});
    });
  });
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder, warnIfMissed: false);
}

Future<void> _enterField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final finder = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.enterText(finder, value);
}

Future<void> _pumpForm(
  WidgetTester tester, {
  bool submitting = false,
  Future<void> Function(OutletFormData form)? onSubmit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OutletForm(
              submitting: submitting,
              onSubmit: onSubmit ?? (_) async {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
