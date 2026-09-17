import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/cash_payment/actions/cash_payment_action_button.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment_method/widgets/totals/continue_payment_button.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';

void main() {
  for (final primary in [TenantAdminColors.primary, const Color(0xFFFF1493)]) {
    for (final mode in ['enabled', 'disabled', 'loading']) {
      testWidgets('shared collection payment actions use $primary in $mode',
          (tester) async {
        var calls = 0;
        final enabled = mode == 'enabled';
        final VoidCallback? action = mode == 'disabled' ? null : () => calls++;
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: primary)
                  .copyWith(primary: primary)),
          home: Scaffold(
              body: Column(children: [
            ContinuePaymentButton(
                onPressed: action, isLoading: mode == 'loading'),
            CashPaymentActionButton(
                label: 'Complete Payment',
                icon: Icons.check,
                isPrimary: true,
                isLoading: mode == 'loading',
                onPressed: action),
          ])),
        ));
        final buttons = find.byType(FilledButton);
        expect(buttons, findsNWidgets(2));
        for (var index = 0; index < 2; index++) {
          final button = tester.widget<FilledButton>(buttons.at(index));
          final states = enabled ? <WidgetState>{} : {WidgetState.disabled};
          expect(button.style!.backgroundColor!.resolve(states),
              enabled ? primary : PosPrimaryActionTokens.disabledBackground);
          expect(button.onPressed != null, enabled);
          await tester.tap(buttons.at(index));
        }
        expect(calls, enabled ? 2 : 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
