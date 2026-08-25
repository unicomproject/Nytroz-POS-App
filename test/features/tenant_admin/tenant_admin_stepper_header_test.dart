import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/widgets/tenant_admin_stepper_header.dart';

void main() {
  const steps = [
    'Select Role',
    'Select Modules',
    'Configure\nPermissions',
    'Assign Users\n& Access',
    'Review\n& Save',
  ];

  testWidgets('uses compact progress on tablet portrait widths',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(768, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 768,
            child: TenantAdminStepperHeader(
              steps: steps,
              currentStep: 2,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Step 3 of 5'), findsOneWidget);
    expect(find.text('Configure Permissions'), findsOneWidget);
  });

  testWidgets('uses the full workflow indicator on tablet landscape widths',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1024,
            child: TenantAdminStepperHeader(
              steps: steps,
              currentStep: 2,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Step 3 of 5'), findsNothing);
    expect(find.text('Select Role'), findsOneWidget);
    expect(find.text('Review\n& Save'), findsOneWidget);
  });
}
