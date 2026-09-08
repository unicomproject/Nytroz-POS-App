import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_payment_permission_visibility.dart';
import '../../../../providers/pos_checkout_summary_provider.dart';
import '../../payment_method_style.dart';

class PaymentFinancialSummary extends ConsumerWidget {
  const PaymentFinancialSummary({
    super.key,
    required this.summary,
    this.surface = PaymentSummaryPermissionSurface.checkout,
  });

  final PosCheckoutSummaryViewData summary;
  final PaymentSummaryPermissionSurface surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    final currency = summary.currency;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final showSubtotal = surface == PaymentSummaryPermissionSurface.checkout
        ? PosPaymentPermissionVisibility.canShowCheckoutSummarySubtotal(
            permissions,
          )
        : PosPaymentPermissionVisibility.canShowCashSummarySubtotal(
            permissions,
          );
    final showDiscount = surface == PaymentSummaryPermissionSurface.checkout
        ? PosPaymentPermissionVisibility.canShowCheckoutSummaryDiscount(
            permissions,
          )
        : PosPaymentPermissionVisibility.canShowCashSummaryDiscount(
            permissions,
          );
    final showTax = surface == PaymentSummaryPermissionSurface.checkout
        ? PosPaymentPermissionVisibility.canShowCheckoutSummaryTax(permissions)
        : PosPaymentPermissionVisibility.canShowCashSummaryTax(permissions);
    final showTotal = surface == PaymentSummaryPermissionSurface.checkout
        ? PosPaymentPermissionVisibility.canShowCheckoutSummaryTotal(
            permissions,
          )
        : PosPaymentPermissionVisibility.canShowCashSummaryTotalDue(
            permissions,
          );

    if (!showSubtotal && !showDiscount && !showTax && !showTotal) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey('payment-financial-summary'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSubtotal)
            _FinancialRow(
              label: 'Subtotal',
              value: paymentMoney(summary.subtotal, currency),
            ),
          if (showDiscount && summary.discount > 0)
            _FinancialRow(
              label: 'Discount',
              value: '- ${paymentMoney(summary.discount, currency)}',
              valueColor: const Color(0xFF16A34A),
            ),
          if (showTax)
            _FinancialRow(
              label: 'Tax',
              value: paymentMoney(summary.tax, currency),
              showInfoIcon: true,
            ),
          if (showTotal) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL DUE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: PaymentMethodStyle.navy,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    paymentMoney(summary.totalPayable, currency),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FinancialRow extends StatelessWidget {
  const _FinancialRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.showInfoIcon = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool showInfoIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                if (showInfoIcon) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? PaymentMethodStyle.navy,
            ),
          ),
        ],
      ),
    );
  }
}
