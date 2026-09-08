import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_payment_permission_visibility.dart';
import '../../../../providers/pos_checkout_summary_provider.dart';
import '../../payment_method_style.dart';

class PaymentTotalDueCard extends ConsumerWidget {
  const PaymentTotalDueCard({
    super.key,
    required this.summary,
  });

  final PosCheckoutSummaryViewData summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    if (!PosPaymentPermissionVisibility.canShowCheckoutSummaryTotal(
      permissions,
    )) {
      return const SizedBox.shrink();
    }

    final primaryColor = Theme.of(context).colorScheme.primary;
    final currency = summary.currency;

    return Container(
      key: const ValueKey('payment-right-total-due-card'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: PaymentMethodStyle.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'TOTAL DUE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                paymentMoney(summary.totalPayable, currency),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 52,
            color: Color(0xFFE2E8F0),
          ),
        ],
      ),
    );
  }
}
