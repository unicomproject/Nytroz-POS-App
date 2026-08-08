import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet_create_options.dart';
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
    });

    testWidgets('blocks malformed country codes before submit', (tester) async {
      var submitted = false;
      await _pumpForm(
        tester,
        initialValue: _initialFormWithCountry('LKA'),
        useCreateOptions: false,
        onSubmit: (_) async => submitted = true,
      );
      await tester.enterText(find.byType(TextFormField).first, 'Main Store');
      await _tapText(tester, 'Next');
      await tester.pumpAndSettle();

      await _tapText(tester, 'Next');
      await tester.pumpAndSettle();

      expect(find.textContaining('Country Code must be 2'), findsOneWidget);
      expect(submitted, isFalse);
    });

    testWidgets('country dropdown never displays object string',
        (tester) async {
      OutletFormData? submittedForm;
      await _pumpForm(
        tester,
        createOptions: _createOptions,
        onSubmit: (form) async => submittedForm = form,
      );

      await tester.enterText(find.byType(TextFormField).first, 'Main Store');
      await _tapText(tester, 'Next');
      await tester.pumpAndSettle();

      expect(find.text('{code: LK, name: Sri Lanka}'), findsNothing);
      expect(submittedForm, isNull);
    });

    testWidgets('outlet type labels validate through canonical values',
        (tester) async {
      await _pumpForm(tester);

      expect(find.text('Store'), findsOneWidget);
      expect(find.text('{value: STORE, label: Store}'), findsNothing);

      await tester.enterText(find.byType(TextFormField).first, 'Main Store');
      await _tapText(tester, 'Next');
      await tester.pumpAndSettle();

      expect(
          find.text('Outlet type must be STORE or WAREHOUSE.'), findsNothing);
      expect(find.text('Select a valid outlet type.'), findsNothing);
    });

    testWidgets('unsupported outlet type fails validation', (tester) async {
      await _pumpForm(
        tester,
        initialValue: _initialFormWithOutletType(
          '{value: STORE, label: Store}',
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Main Store');
      await _tapText(tester, 'Next');
      await tester.pumpAndSettle();

      expect(find.text('Outlet type is required.'), findsOneWidget);
      expect(find.text('{value: STORE, label: Store}'), findsNothing);
    });

    testWidgets('edit form preserves warehouse canonical value',
        (tester) async {
      OutletFormData? submittedForm;
      await _pumpForm(
        tester,
        initialValue: _initialFormWithOutletType('WAREHOUSE'),
        onSubmit: (form) async => submittedForm = form,
      );

      expect(find.text('Warehouse'), findsOneWidget);
      expect(submittedForm, isNull);
    });

    testWidgets('timezone dropdown stores canonical timezone value only',
        (tester) async {
      await _pumpForm(tester);
      expect(find.text('Europe/London'), findsOneWidget);
      expect(find.text('{value: Europe/London, label: Europe/London}'),
          findsNothing);

      await tester.enterText(find.byType(TextFormField).first, 'Main Store');
      await _tapText(tester, 'Next');
      await tester.pumpAndSettle();
    });

    testWidgets('timezone object strings are not accepted or stored',
        (tester) async {
      await _pumpForm(
        tester,
        initialValue: _initialFormWithTimezone(
          '{value: Europe/London, label: Europe/London}',
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Main Store');
      await _tapText(tester, 'Next');
      await tester.pumpAndSettle();

      expect(find.text('Timezone is required.'), findsOneWidget);
      expect(find.text('{value: Europe/London, label: Europe/London}'),
          findsNothing);
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
  await tester.tap(finder);
}

Future<void> _pumpForm(
  WidgetTester tester, {
  bool submitting = false,
  OutletFormData? initialValue,
  OutletCreateOptions? createOptions,
  bool useCreateOptions = true,
  Future<void> Function(OutletFormData form)? onSubmit,
}) async {
  tester.view.physicalSize = const Size(800, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutletForm(
                initialValue: initialValue,
                submitting: submitting,
                createOptions: useCreateOptions
                    ? createOptions ?? _createOptions
                    : createOptions,
                onSubmit: onSubmit ?? (_) async {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

OutletFormData _initialFormWithCountry(String country) {
  return OutletFormData(
    outletName: 'Main Store',
    outletType: 'STORE',
    status: 'ACTIVE',
    mainPhoneNumber: '',
    emailAddress: '',
    addressLine1: '10 Main Street',
    city: 'Colombo',
    country: country,
    postalCode: '',
    timezone: 'Asia/Colombo',
    openingHours: const [],
  );
}

OutletFormData _initialFormWithOutletType(String outletType) {
  return OutletFormData(
    outletName: 'Main Store',
    outletType: outletType,
    status: 'ACTIVE',
    mainPhoneNumber: '',
    emailAddress: '',
    addressLine1: '10 Main Street',
    city: 'Colombo',
    country: 'LK',
    postalCode: '',
    timezone: 'Europe/London',
    openingHours: const [],
  );
}

OutletFormData _initialFormWithTimezone(String timezone) {
  return OutletFormData(
    outletName: 'Main Store',
    outletType: 'STORE',
    status: 'ACTIVE',
    mainPhoneNumber: '',
    emailAddress: '',
    addressLine1: '10 Main Street',
    city: 'Colombo',
    country: 'LK',
    postalCode: '',
    timezone: timezone,
    openingHours: const [],
  );
}

const _createOptions = OutletCreateOptions(
  outletTypes: [
    OutletSelectOption(value: 'STORE', label: 'Store'),
    OutletSelectOption(value: 'WAREHOUSE', label: 'Warehouse'),
  ],
  countries: [
    OutletCountryOption(code: 'LK', name: 'Sri Lanka'),
    OutletCountryOption(code: 'IN', name: 'India'),
  ],
  timezones: [
    OutletSelectOption(value: 'Europe/London', label: 'Europe/London'),
    OutletSelectOption(value: 'Asia/Colombo', label: 'Asia/Colombo'),
  ],
  defaults: OutletCreateDefaults(
    countryCode: 'LK',
    timezone: 'Europe/London',
    status: 'ACTIVE',
  ),
);
