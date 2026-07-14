import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment/pos_bottom_action_buttons.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

void main() {
  testWidgets('enabled primary action uses the cashier gradient theme',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PosPrimaryActionButton(
            key: const Key('primary-action'),
            label: 'Continue',
            onPressed: () {},
          ),
        ),
      ),
    );

    final decoration = _buttonDecoration(tester);
    final gradient = decoration.gradient! as LinearGradient;

    expect(
      gradient.colors,
      [TenantAdminColors.navySoft, TenantAdminColors.primary],
    );
  });

  testWidgets('disabled primary action uses the disabled surface',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PosPrimaryActionButton(
            key: Key('primary-action'),
            label: 'Continue',
            onPressed: null,
          ),
        ),
      ),
    );

    final decoration = _buttonDecoration(tester);

    expect(decoration.gradient, isNull);
    expect(decoration.color, TenantAdminColors.border);
  });
}

BoxDecoration _buttonDecoration(WidgetTester tester) {
  final decoratedBox = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byKey(const Key('primary-action')),
      matching: find.byType(DecoratedBox),
    ),
  );
  return decoratedBox.decoration as BoxDecoration;
}
