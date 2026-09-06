import 'package:flutter/material.dart';

import '../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../../pos/presentation/widgets/new_sale/navigation/pos_cashier_bottom_navigation.dart';
import '../../../../../pos_shell/presentation/widgets/common/pos_top_bar.dart';
import '../../../../../pos_shell/presentation/widgets/common/pos_top_bar_notification_button.dart';
import '../../../../domain/entities/pos_payment_method_type.dart';
import '../../../providers/pos_checkout_summary_provider.dart';
import '../payment_method_style.dart';
import '../widgets/payment_method_workspace_card.dart';
import '../widgets/payment_top_bar_content.dart';
import '../widgets/right_payment_column.dart';
import '../widgets/sale_summary/left_payment_summary_column.dart';

class PaymentMethodPage extends StatelessWidget {
  const PaymentMethodPage({
    super.key,
    required this.summary,
    required this.cart,
    required this.allowedMethods,
    required this.selectedMethod,
    required this.isNavigating,
    required this.onSelectMethod,
    required this.onContinue,
    this.onCustomerTap,
    this.onBackToSale,
    this.showChrome = true,
  });

  final PosCheckoutSummaryViewData summary;
  final PosNewSaleCartState cart;
  final Set<PosPaymentMethodType> allowedMethods;
  final PosPaymentMethodType? selectedMethod;
  final bool isNavigating;
  final ValueChanged<PosPaymentMethodType> onSelectMethod;
  final VoidCallback? onContinue;
  final VoidCallback? onCustomerTap;
  final VoidCallback? onBackToSale;
  final bool showChrome;

  @override
  Widget build(BuildContext context) => ColoredBox(
        key: const ValueKey('payment-method-page'),
        color: PaymentMethodStyle.background,
        child: Column(
          children: [
            if (showChrome)
              const PosTopBar(
                content: PaymentTopBarContent(),
                trailing: PosTopBarNotificationButton(dark: true),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 920;
                  final padding = constraints.maxWidth >= 1200 ? 14.0 : 10.0;
                  final leftFlex = constraints.maxWidth >= 1150 ? 36 : 44;
                  final rightFlex = 100 - leftFlex;

                  if (wide) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(padding, 8, padding, 8),
                      child: PaymentMethodWorkspaceCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: leftFlex,
                              child: LeftPaymentSummaryColumn(
                                cart: cart,
                                summary: summary,
                                onCustomerTap: onCustomerTap,
                              ),
                            ),
                            const SizedBox(width: PaymentMethodStyle.gap),
                            Expanded(
                              flex: rightFlex,
                              child: RightPaymentColumn(
                                summary: summary,
                                allowedMethods: allowedMethods,
                                selectedMethod: selectedMethod,
                                isNavigating: isNavigating,
                                onSelectMethod: onSelectMethod,
                                onContinue: onContinue,
                                onBackToSale: onBackToSale,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    child: PaymentMethodWorkspaceCard(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 600,
                            child: LeftPaymentSummaryColumn(
                              cart: cart,
                              summary: summary,
                              onCustomerTap: onCustomerTap,
                            ),
                          ),
                          const SizedBox(height: PaymentMethodStyle.gap),
                          SizedBox(
                            height: 620,
                            child: RightPaymentColumn(
                              summary: summary,
                              allowedMethods: allowedMethods,
                              selectedMethod: selectedMethod,
                              isNavigating: isNavigating,
                              onSelectMethod: onSelectMethod,
                              onContinue: onContinue,
                              onBackToSale: onBackToSale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (showChrome) const PosCashierBottomNavigation(),
          ],
        ),
      );
}
