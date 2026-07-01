import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../customer/presentation/providers/customer_search_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/pos_cash_payment_success_provider.dart';
import '../providers/pos_email_receipt_form_provider.dart';
import '../widgets/cash_payment/cash_sale_summary_card.dart';
import '../widgets/cash_payment_success/cash_payment_success_header.dart';
import '../widgets/cash_payment_success/items_purchased_card.dart';
import '../widgets/cash_payment_success/payment_details_card.dart';
import '../widgets/cash_payment_success/payment_success_banner.dart';
import '../widgets/cash_payment_success/receipt_action_bar.dart';

class PosCashPaymentSuccessScreen extends ConsumerWidget {
  const PosCashPaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final successData = ref.watch(posCashPaymentSuccessProvider);

    if (!PosPermissionAccess.canViewPaymentSuccessSession(session)) {
      return const TenantAdminForbiddenScreen();
    }

    if (successData == null) {
      return _MissingSuccessFallback(
        onBack: () => context.go('/pos/new-sale'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final granted = session?.permissionCodes.toSet() ?? const <String>{};
        final canViewSales = PosPermissionAccess.canViewSales(granted);
        final canViewPaymentDetails =
            canViewSales || PosPermissionAccess.canAcceptCashPayment(granted);
        final canPrintReceipt = PosPermissionAccess.canPrintReceipts(granted);
        final canStartNewSale = PosPermissionAccess.canAccessNewSale(granted);
        final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);
        final useWideLayout =
            constraints.maxWidth >= TenantAdminBreakpoints.tablet;

        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CashPaymentSuccessHeader(
                onBack: () => context.go('/pos/new-sale'),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              PaymentSuccessBanner(
                receiptNumber: successData.receiptNumber,
                completedAtLabel:
                    formatReceiptDateTime(successData.completedAt),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              Expanded(
                child: useWideLayout
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (canViewSales || canViewPaymentDetails)
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  if (canViewSales) ...[
                                    CashSaleSummaryCard(
                                      itemCount: successData.itemCount,
                                      subtotal: successData.subtotal,
                                      discount: successData.discount,
                                      tax: successData.tax,
                                      total: successData.total,
                                    ),
                                    const SizedBox(
                                      height: TenantAdminSpacing.lg,
                                    ),
                                  ],
                                  if (canViewPaymentDetails)
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: PaymentDetailsCard(
                                          cashReceived:
                                              successData.cashReceived,
                                          changeDue: successData.changeDue,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if ((canViewSales || canViewPaymentDetails) &&
                              canViewSales)
                            const SizedBox(width: TenantAdminSpacing.lg),
                          if (canViewSales)
                            Expanded(
                              flex: 3,
                              child: SingleChildScrollView(
                                child: ItemsPurchasedCard(
                                  items: successData.items,
                                  itemCount: successData.itemCount,
                                  total: successData.total,
                                ),
                              ),
                            )
                          else
                            const Expanded(
                              child: _ReceiptDetailsRestricted(),
                            ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (canViewSales) ...[
                              CashSaleSummaryCard(
                                itemCount: successData.itemCount,
                                subtotal: successData.subtotal,
                                discount: successData.discount,
                                tax: successData.tax,
                                total: successData.total,
                              ),
                              const SizedBox(height: TenantAdminSpacing.lg),
                            ],
                            if (canViewPaymentDetails) ...[
                              PaymentDetailsCard(
                                cashReceived: successData.cashReceived,
                                changeDue: successData.changeDue,
                              ),
                              const SizedBox(height: TenantAdminSpacing.lg),
                            ],
                            if (canViewSales)
                              ItemsPurchasedCard(
                                items: successData.items,
                                itemCount: successData.itemCount,
                                total: successData.total,
                              )
                            else
                              const _ReceiptDetailsRestricted(),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              ReceiptActionBar(
                onPrintReceipt: canPrintReceipt
                    ? () => context.push(
                          '/pos/new-sale/payment/cash/success/print-receipt',
                        )
                    : null,
                onNewSale:
                    canStartNewSale ? () => _startNewSale(context, ref) : null,
                onViewSales: canViewSales ? () => _viewSales(context) : null,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showActionMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _startNewSale(BuildContext context, WidgetRef ref) {
    ref.read(posNewSaleCartProvider.notifier).clear();
    ref.read(posCashPaymentSuccessProvider.notifier).clear();
    ref.read(posEmailReceiptFormProvider.notifier).clear();
    ref.read(selectedCustomerProvider.notifier).state = null;
    context.go('/pos/new-sale');
  }

  void _viewSales(BuildContext context) {
    _showActionMessage(context, 'Orders screen is not available yet.');
  }
}

class _ReceiptDetailsRestricted extends StatelessWidget {
  const _ReceiptDetailsRestricted();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 40,
              color: TenantAdminColors.mutedText,
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              'Sale details restricted',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              'You can view the receipt status, but sale line details require sales view permission.',
              textAlign: TextAlign.center,
              style: TenantAdminTextStyles.muted(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingSuccessFallback extends StatelessWidget {
  const _MissingSuccessFallback({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: TenantAdminColors.mutedText,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            'Payment receipt unavailable',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'Complete a cash payment to view the receipt summary.',
            textAlign: TextAlign.center,
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          FilledButton(
            onPressed: onBack,
            child: const Text('Back to New Sale'),
          ),
        ],
      ),
    );
  }
}
