import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_payment_method_type.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment/payment_method_card.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment_method/widgets/payment_selection/payment_methods_section.dart';

/// Payment method tiles require container + each accept child (no parent infer).
final _allPaymentAcceptPermissions = EffectivePermissionSet.fromIterable({
  PosPermissionCodes.checkoutMethodsContainer,
  PosPermissionCodes.checkoutSale,
  PosPermissionCodes.acceptCashPayment,
  PosPermissionCodes.acceptCardPayment,
  PosPermissionCodes.acceptQrPayment,
  PosPermissionCodes.acceptSplitPayment,
});

EffectivePermissionSet _permissionsFor(Set<PosPaymentMethodType> methods) {
  return EffectivePermissionSet.fromIterable({
    PosPermissionCodes.checkoutMethodsContainer,
    PosPermissionCodes.checkoutSale,
    if (methods.contains(PosPaymentMethodType.cash))
      PosPermissionCodes.acceptCashPayment,
    if (methods.contains(PosPaymentMethodType.card))
      PosPermissionCodes.acceptCardPayment,
    if (methods.contains(PosPaymentMethodType.qrMobile))
      PosPermissionCodes.acceptQrPayment,
    if (methods.contains(PosPaymentMethodType.split))
      PosPermissionCodes.acceptSplitPayment,
  });
}

void main() {
  for (var count = 0; count <= 4; count++) {
    testWidgets('renders exactly $count backend-authorized methods',
        (tester) async {
      final methods = PosPaymentMethodType.values.take(count).toSet();
      await tester.binding.setSurfaceSize(const Size(900, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          effectivePermissionSetProvider.overrideWithValue(
            count == 0
                ? _allPaymentAcceptPermissions
                : _permissionsFor(methods),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 500,
              child: PaymentMethodsSection(
                allowedMethods: methods,
                authoritative: true,
                selectedMethod: null,
                onSelectMethod: (_) {},
              ),
            ),
          ),
        ),
      ));

      expect(find.byType(PaymentMethodCard), findsNWidgets(count));
      expect(
        find.byKey(const ValueKey('payment-methods-empty')),
        count == 0 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('card tap selects only and does not navigate', (tester) async {
    PosPaymentMethodType? selected;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        effectivePermissionSetProvider.overrideWithValue(
          _permissionsFor({PosPaymentMethodType.cash}),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 500,
            child: PaymentMethodsSection(
              allowedMethods: const {PosPaymentMethodType.cash},
              authoritative: true,
              selectedMethod: null,
              onSelectMethod: (method) => selected = method,
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(PaymentMethodCard));
    expect(selected, PosPaymentMethodType.cash);
    expect(find.byType(PaymentMethodsSection), findsOneWidget);
  });
}
