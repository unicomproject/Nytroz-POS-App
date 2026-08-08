import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet_details.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/widgets/outlet_form.dart';

void main() {
  testWidgets('debug validation', (tester) async {
    tester.view.physicalSize = const Size(800, 1500);
    tester.view.devicePixelRatio = 1.0;
    
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OutletForm(
                  initialValue: OutletFormData(
                    outletName: 'Main Store',
                    outletType: '{value: STORE, label: Store}',
                    status: 'ACTIVE',
                    mainPhoneNumber: '',
                    emailAddress: '',
                    addressLine1: '10 Main Street',
                    city: 'Colombo',
                    country: 'LK',
                    postalCode: '',
                    timezone: 'Europe/London',
                    openingHours: const [],
                  ),
                  submitting: false,
                  createOptions: OutletCreateOptions(
                    outletTypes: [
                      OutletSelectOption(value: 'STORE', label: 'Store'),
                      OutletSelectOption(value: 'WAREHOUSE', label: 'Warehouse'),
                    ],
                    countries: [],
                    timezones: [],
                    defaults: OutletCreateDefaults(countryCode: '', timezone: '', status: 'ACTIVE'),
                  ),
                  onSubmit: (_) async {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nextFinder = find.text('Next');
    await tester.tap(nextFinder);
    await tester.pumpAndSettle();

    final texts = tester.widgetList<Text>(find.byType(Text));
    for (var textWidget in texts) {
      if (textWidget.data?.contains('type') == true || textWidget.data?.contains('Outlet') == true) {
        print('TEXT: ${textWidget.data}');
      }
    }
  });
}
