import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet_details.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/widgets/outlet_form.dart';

void main() {
  testWidgets('dump text widgets', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OutletForm(
                  initialValue: null,
                  submitting: false,
                  createOptions: OutletCreateOptions(
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

    await tester.enterText(find.byType(TextFormField).first, 'Main Store');
    
    final nextFinder = find.text('Next');
    await tester.ensureVisible(nextFinder);
    await tester.pumpAndSettle();
    await tester.tap(nextFinder);
    await tester.pumpAndSettle();

    final texts = tester.widgetList<Text>(find.byType(Text));
    for (var textWidget in texts) {
      print('FOUND TEXT: ${textWidget.data}');
    }
  });
}
