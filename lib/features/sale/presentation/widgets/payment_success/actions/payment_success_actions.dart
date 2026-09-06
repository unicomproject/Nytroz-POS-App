import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_payment_permission_visibility.dart';

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
    final permissions = ref.watch(effectivePermissionSetProvider);
    final printState = ref.watch(completedSalePrintProvider);
    final isPrinting = printState.status == CompletedSalePrintStatus.printing;
    final alreadyPrinted = printState.saleId == saleId &&
        printState.status == CompletedSalePrintStatus.printed;
    final canPrint =
        PosPaymentPermissionVisibility.canPrintPhysicalReceipt(permissions);
    final canReprint =
        PosPaymentPermissionVisibility.canReprintReceipt(permissions);
    final canNewSale =
        PosPaymentPermissionVisibility.canStartNewSaleFromSuccess(permissions);

    final showPrintAction = alreadyPrinted ? canReprint : canPrint;
    final printLabel = alreadyPrinted ? 'Print Again' : 'Print Receipt';

    if (!showPrintAction && !canNewSale) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (showPrintAction)
          Expanded(
            child: OutlinedButton.icon(
              key: ValueKey(alreadyPrinted
                  ? 'payment-success-reprint'
                  : 'payment-success-print'),
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
        if (showPrintAction && canNewSale)
          const SizedBox(width: TenantAdminSpacing.md),
        if (canNewSale)
          Expanded(
            child: ElevatedButton.icon(
              key: const ValueKey('payment-success-new-sale'),
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
