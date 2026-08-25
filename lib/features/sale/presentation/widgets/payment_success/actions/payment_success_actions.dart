import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../providers/completed_sale_print_provider.dart';
import '../../../providers/pos_cash_payment_intent_provider.dart';
import '../../../providers/pos_cash_payment_provider.dart';
import '../../print_receipt/print_receipt_actions.dart';

class PaymentSuccessActions extends ConsumerWidget {
  const PaymentSuccessActions({
    super.key,
    required this.saleId,
  });

  final String saleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printState = ref.watch(completedSalePrintProvider);
    final isPrinting = printState.status == CompletedSalePrintStatus.printing;
    final printLabel = printState.saleId == saleId &&
            printState.status == CompletedSalePrintStatus.printed
        ? 'Print Again'
        : 'Print Receipt';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isPrinting
                ? null
                : () => executeReceiptPrint(context, ref, saleId),
            icon: const Icon(Icons.print_outlined),
            label: Text(printLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: TenantAdminColors.primary,
              side: const BorderSide(color: TenantAdminColors.primary),
              padding: const EdgeInsets.symmetric(
                vertical: TenantAdminSpacing.lg,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _startNewSale(context, ref);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Start New Sale'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TenantAdminColors.posHomeAccentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: TenantAdminSpacing.lg,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startNewSale(BuildContext context, WidgetRef ref) {
    ref.read(posNewSaleCartProvider.notifier).clear();
    ref.invalidate(posCashPaymentIntentProvider);
    ref.read(posCashPaymentProvider.notifier).clearAmount();
    context.go('/pos/new-sale');
  }
}
