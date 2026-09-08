import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/widgets/till_form.dart';

void main() {
  testWidgets('edit form locks outlet when assign permission is missing',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TillForm(
              outlets: const [
                OutletOption(
                  id: 'outlet-1',
                  name: 'Main Outlet',
                  code: 'MAIN',
                  status: 'ACTIVE',
                ),
              ],
              initialValue: const TillFormData(
                name: 'Front Till',
                code: 'TILL-01',
                outletId: 'outlet-1',
                status: 'active',
              ),
              backendErrors: const {},
              submitting: false,
              showHardwareSection: false,
              canChangeOutlet: false,
              onSubmit: (_) async {},
            ),
          ),
        ),
      ),
    );

    final outletDropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).first,
    );

    expect(outletDropdown.onChanged, isNull);
    expect(
      find.text('You do not have permission to change the assigned outlet.'),
      findsOneWidget,
    );
  });
}
