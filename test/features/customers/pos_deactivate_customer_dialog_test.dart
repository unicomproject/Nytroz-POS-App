import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/customers/presentation/widgets/pos_deactivate_customer_dialog.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

void main() {
  testWidgets('deactivate dialog uses POS orange theme and shared blur route',
      (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  result = await showPosDeactivateCustomerDialog(
                    context: context,
                    customerName: 'Sundhar',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Deactivate customer?'), findsOneWidget);
    expect(
      find.text('Sundhar will no longer be eligible for new sales.'),
      findsOneWidget,
    );
    expect(find.byType(PosDeactivateCustomerDialog), findsOneWidget);

    final route = ModalRoute.of(
      tester.element(find.byType(PosDeactivateCustomerDialog)),
    );
    expect(route?.filter, isNotNull);
    expect(appModalBlurSigma, 12);

    final icon =
        tester.widget<Icon>(find.byIcon(Icons.person_off_outlined).first);
    expect(icon.color, TenantAdminColors.posHomeAccentOrange);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
