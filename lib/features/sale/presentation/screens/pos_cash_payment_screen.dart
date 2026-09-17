import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../fulfilment_pickup/presentation/providers/pos_online_order_collection_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/pos_checkout_api_exception.dart';
import '../../domain/entities/pos_payment_method_type.dart';
import '../providers/pos_cash_payment_intent_provider.dart';
import '../providers/pos_cash_payment_provider.dart';
import '../providers/pos_cash_payment_success_provider.dart';
import '../providers/pos_checkout_summary_provider.dart';
import '../../../hardware/receipt_printer/presentation/providers/cash_drawer_controller.dart';
import '../../../pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import '../widgets/cash_payment/cash_payment_screen_body.dart';
import '../widgets/print_receipt/print_receipt_actions.dart';
import 'dart:developer' as developer;

class PosCashPaymentScreen extends ConsumerStatefulWidget {
  const PosCashPaymentScreen({super.key});

  @override
  ConsumerState<PosCashPaymentScreen> createState() =>
      _PosCashPaymentScreenState();
}

class _PosCashPaymentScreenState extends ConsumerState<PosCashPaymentScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final cart = ref.watch(posNewSaleCartProvider);
    final cashState = ref.watch(posCashPaymentProvider);
    final intent = ref.watch(posCashPaymentIntentProvider);
    final collection = ref.watch(collectionPaymentContextProvider);

    if (!PosPermissionAccess.canAccessCashPaymentScreenSession(session)) {
      return const TenantAdminForbiddenScreen();
    }

    // Recovery must remain reachable even if the cart summary cannot load.
    if (cart.completedSaleId != null ||
        (intent != null && intent.phase != CashPaymentIntentPhase.draft)) {
      final unknown = intent?.phase == CashPaymentIntentPhase.unknown;
      final completed = cart.completedSaleId != null ||
          intent?.phase == CashPaymentIntentPhase.succeeded;
      final busy =
          _isSubmitting || intent?.phase == CashPaymentIntentPhase.inFlight;
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(completed
              ? 'This sale is completed.'
              : unknown
                  ? 'Payment outcome is not yet confirmed. Do not take payment again.'
                  : busy
                      ? 'Confirming payment…'
                      : 'Payment was rejected. Your cart is retained.'),
          const SizedBox(height: 16),
          if (!busy)
            ElevatedButton(
              key: ValueKey(completed
                  ? 'cash-view-receipt'
                  : unknown
                      ? 'cash-check-payment-status'
                      : 'cash-start-new-attempt'),
              onPressed: completed
                  ? () {
                      if (collection != null ||
                          ref
                                  .read(posOnlineOrderCollectionProvider)
                                  .validation !=
                              null) {
                        context.go(
                          '/pos/online-orders/collection/payment-success',
                        );
                      } else {
                        context.go('/pos/new-sale/payment/cash/success');
                      }
                    }
                  : unknown
                      ? _reconcilePayment
                      : () => ref
                          .read(posCashPaymentIntentProvider.notifier)
                          .startNew(intent!.saleIdentity),
              child: Text(completed
                  ? 'View Receipt'
                  : unknown
                      ? 'Check Payment Status'
                      : 'Start New Attempt'),
            ),
          if (busy) const CircularProgressIndicator(),
        ]),
      );
    }

    if (!cart.hasItems && collection == null) {
      return _EmptyCartFallback(onBack: () => context.pop());
    }

    if (collection != null) {
      final summary = PosCheckoutSummaryViewData(
        itemCount: 0,
        subtotal: collection.amountDue,
        discount: 0,
        tax: 0,
        totalPayable: collection.amountDue,
        saleType: 'Click & Collect',
        itemsInCart: 0,
        saleDate: DateTime.now(),
        cashierName: session?.userDisplayName.trim().isNotEmpty == true
            ? session!.userDisplayName.trim()
            : 'Cashier',
        paymentMethods: const [PosPaymentMethodType.cash],
        usedFallback: false,
        currency: collection.currency,
      );
      final total = summary.totalPayable;
      final cashReceived = cashState.cashReceived;
      final canConfirm = canConfirmCashPayment(cashReceived, total);
      final onKeyTap = ref.read(posCashPaymentProvider.notifier).appendKey;

      return LayoutBuilder(
        builder: (context, constraints) {
          final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              padding.left > 16 ? 16 : padding.left,
              padding.top > 12 ? 12 : padding.top,
              padding.right > 16 ? 16 : padding.right,
              padding.bottom > 12 ? 12 : padding.bottom,
            ),
            child: CashPaymentScreenBody(
              cart: cart,
              summary: summary,
              cashReceived: cashReceived,
              inputBuffer: cashState.inputBuffer,
              quickAmounts: generateCashQuickAmounts(total),
              selectedQuickAmount: cashState.selectedQuickAmount,
              onCustomerTap: () {},
              onBackToPaymentMethods: () => context.pop(),
              onQuickAmountSelected: (amount) => ref
                  .read(posCashPaymentProvider.notifier)
                  .setAmount(amount, selectedQuickAmount: amount),
              onDigitPressed: onKeyTap,
              onDoubleZeroPressed: () => onKeyTap('00'),
              onBackspacePressed: () => onKeyTap('backspace'),
              onClearPressed: () =>
                  ref.read(posCashPaymentProvider.notifier).clearAmount(),
              isSubmitting: _isSubmitting,
              canCompleteSale: canConfirm,
              onCompleteSalePressed: () => _confirmCashPayment(summary),
            ),
          );
        },
      );
    }

    return ref.watch(posCheckoutSummaryProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CheckoutErrorFallback(
            message: error is PosCheckoutApiException
                ? error.message
                : 'Unable to load checkout summary.',
            onBack: () => context.pop(),
            onRetry: () => ref.invalidate(posCheckoutSummaryProvider),
          ),
          data: (summary) {
            if (summary.usedFallback) {
              return _CheckoutErrorFallback(
                message: summary.fallbackMessage ??
                    checkoutFallbackUnavailableMessage,
                onBack: () => context.pop(),
                onRetry: () => ref.invalidate(posCheckoutSummaryProvider),
              );
            }

            final total = summary.totalPayable;
            final cashReceived = cashState.cashReceived;
            final canConfirm = canConfirmCashPayment(cashReceived, total);
            final onKeyTap =
                ref.read(posCashPaymentProvider.notifier).appendKey;

            return LayoutBuilder(
              builder: (context, constraints) {
                final padding =
                    TenantAdminInsets.pageForWidth(constraints.maxWidth);

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding.left > 16 ? 16 : padding.left,
                    padding.top > 12 ? 12 : padding.top,
                    padding.right > 16 ? 16 : padding.right,
                    padding.bottom > 12 ? 12 : padding.bottom,
                  ),
                  child: CashPaymentScreenBody(
                    cart: cart,
                    summary: summary,
                    cashReceived: cashReceived,
                    inputBuffer: cashState.inputBuffer,
                    quickAmounts: generateCashQuickAmounts(total),
                    selectedQuickAmount: cashState.selectedQuickAmount,
                    onCustomerTap: () =>
                        context.push('/pos/new-sale/payment/customer'),
                    onBackToPaymentMethods: () => context.pop(),
                    onQuickAmountSelected: (amount) => ref
                        .read(posCashPaymentProvider.notifier)
                        .setAmount(amount, selectedQuickAmount: amount),
                    onDigitPressed: onKeyTap,
                    onDoubleZeroPressed: () => onKeyTap('00'),
                    onBackspacePressed: () => onKeyTap('backspace'),
                    onClearPressed: () =>
                        ref.read(posCashPaymentProvider.notifier).clearAmount(),
                    isSubmitting: _isSubmitting,
                    canCompleteSale: canConfirm,
                    onCompleteSalePressed: () => _confirmCashPayment(summary),
                  ),
                );
              },
            );
          },
        );
  }

  Future<void> _confirmCashPayment(
    PosCheckoutSummaryViewData summary,
  ) async {
    // Double-tap guard: block if already submitting.
    if (_isSubmitting) return;

    final cashReceived = ref.read(posCashPaymentProvider).cashReceived;
    if (!canConfirmCashPayment(cashReceived, summary.totalPayable)) {
      return;
    }

    final session = ref.read(authSessionProvider);
    final grantedPermissions = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canContinueWithPaymentPermission(
      grantedPermissions,
      PosPaymentMethodType.cash.permissionCode,
    )) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'You do not have permission to accept cash payments.',
      );
      return;
    }

    final cart = ref.read(posNewSaleCartProvider);
    final collection = ref.read(collectionPaymentContextProvider);
    if (cart.completedSaleId != null) return;
    if (cart.itemList.isEmpty && collection == null) {
      _showSnackBar(context, 'Checkout requires valid cart items.');
      return;
    }

    final deviceContext = ref.read(deviceActivationProvider).deviceContext;
    if (deviceContext == null) {
      _showSnackBar(context, 'Checkout requires an activated device.');
      return;
    }

    // Acquire submission lock immediately after all local checks pass.
    setState(() => _isSubmitting = true);

    // Build a stable cart fingerprint for idempotency tracking.
    final saleIdentity = collection != null
        ? 'collection:${collection.salesOrderId}'
        : cart.itemList
            .map((i) => '${i.product.variantId}:${i.quantity}')
            .join('|');
    final requestFingerprint = '$saleIdentity|cash=$cashReceived';

    // Obtain the stable idempotency key from the intent state machine.
    // beginSubmission rejects every concurrent/unknown/completed submission.
    final CashPaymentIntent intent;
    try {
      intent = ref.read(posCashPaymentIntentProvider.notifier).beginSubmission(
            saleIdentity: saleIdentity,
            requestFingerprint: requestFingerprint,
          );
    } on StateError catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackBar(context, e.message);
      }
      return;
    }

    try {
      final payload = await ref
          .read(posCheckoutRemoteDatasourceProvider)
          .startPayment(
            deviceId: deviceContext.deviceId,
            paymentMethod:
                checkoutApiPaymentMethodCode(PosPaymentMethodType.cash),
            lines: collection != null ? const [] : checkoutLinesFromCart(cart),
            cashReceived: cashReceived,
            customerId:
                collection != null ? null : cart.selectedCustomer?.customerId,
            discountApplicationId:
                collection != null ? null : cart.discountApplicationId,
            existingSalesOrderId: collection?.salesOrderId,
            idempotencyKey: intent.key,
          );

      if (collection == null) {
        ref.read(posNewSaleCartProvider.notifier).completeSale(payload.saleId);
      }
      // Mark the intent succeeded — prevents resubmission.
      ref.read(posCashPaymentIntentProvider.notifier).markSucceeded();

      // Store authoritative backend values (not local preview).
      ref.read(posCashPaymentSuccessProvider.notifier).recordCheckoutPayment(
            payload,
          );
      unawaited(
        ref.read(posHomeSessionSummaryProvider.notifier).refresh(),
      );

      if (collection != null) {
        ref
            .read(posOnlineOrderCollectionProvider.notifier)
            .markPaymentSettled(saleId: payload.saleId);
        ref.read(collectionPaymentContextProvider.notifier).state = null;
        ref.read(posCashPaymentIntentProvider.notifier).clear();
        if (!mounted) return;
        context.go('/pos/online-orders/collection/payment-success');
        return;
      }

      // Trigger receipt auto-print + drawer async — never blocks payment success.
      unawaited(
        triggerCheckoutReceiptAutoPrint(
          ref.read,
          saleId: payload.saleId,
        ),
      );

      final drawerPurpose =
          payload.paymentMethod.toUpperCase().contains('SPLIT')
              ? 'splitPaymentCash'
              : 'cashSale';
      if (payload.drawerOperationId != null &&
          payload.cashDrawerSettings != null) {
        final openOnSale =
            payload.cashDrawerSettings!['openOnCashSale'] != false &&
                payload.cashDrawerSettings!['OpenOnCashSale'] != false;
        final openOnSplit =
            payload.cashDrawerSettings!['openOnCashSplit'] != false &&
                payload.cashDrawerSettings!['OpenOnCashSplit'] != false;
        final shouldOpen =
            drawerPurpose == 'splitPaymentCash' ? openOnSplit : openOnSale;
        if (shouldOpen) {
          unawaited(
            ref
                .read(cashDrawerControllerProvider.notifier)
                .triggerAutoOpenForCheckout(
                  drawerOperationId: payload.drawerOperationId!,
                  drawerRequestId: payload.drawerRequestId,
                  purposeStr: drawerPurpose,
                  drawerSettingsJson: payload.cashDrawerSettings!,
                  businessReferenceId: payload.saleId,
                ),
          );
        } else {
          developer.log(
            'Cash drawer auto-open suppressed by configuration. '
            'saleId=${payload.saleId} purpose=$drawerPurpose',
            name: 'pos.drawer',
          );
        }
      } else {
        developer.log(
          'Cash drawer auto-open skipped: missing operation/settings on payment response. '
          'saleId=${payload.saleId} drawerOperationId=${payload.drawerOperationId} '
          'hasSettings=${payload.cashDrawerSettings != null}',
          name: 'pos.drawer',
        );
      }

      if (!mounted) return;

      // Navigate to success only after confirmed backend success.
      context.go('/pos/new-sale/payment/cash/success');
    } on PosCheckoutApiException catch (error) {
      // Distinguish timeout/unknown outcome from confirmed rejections.
      // - Unknown: preserve the same intent key for safe retry.
      // - KnownRejected: require explicit new attempt.
      if (!error.isConfirmedPaymentRejection) {
        ref.read(posCashPaymentIntentProvider.notifier).markUnknown();
      } else {
        ref.read(posCashPaymentIntentProvider.notifier).markKnownRejected();
      }

      if (!mounted) return;
      _showSnackBar(context, error.message);
      // Cart, entered amount, customer and discount are intentionally preserved.
    } on Object {
      // Parsing/cancellation/post-commit uncertainty is not a confirmed rejection.
      if (ref.read(posCashPaymentIntentProvider)?.phase !=
          CashPaymentIntentPhase.succeeded) {
        ref.read(posCashPaymentIntentProvider.notifier).markUnknown();
      }
      if (mounted) {
        _showSnackBar(context, 'Check payment status before trying again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _reconcilePayment() async {
    if (_isSubmitting) return;
    final intent = ref.read(posCashPaymentIntentProvider);
    if (intent?.phase != CashPaymentIntentPhase.unknown) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await ref
          .read(posCheckoutRemoteDatasourceProvider)
          .getPaymentStatus(intent!.key);
      if (!mounted) return;
      if (result.status == 'not_completed') {
        ref.read(posCashPaymentIntentProvider.notifier).markKnownRejected();
        return;
      }
      final payload = result.payment;
      if (payload == null) {
        _showSnackBar(context,
            'Status is still unknown. Your cart is retained. Check again; do not take payment again.');
        return;
      }
      ref
          .read(posCashPaymentSuccessProvider.notifier)
          .recordCheckoutPayment(payload);
      unawaited(
        ref.read(posHomeSessionSummaryProvider.notifier).refresh(),
      );
      ref.read(posCashPaymentIntentProvider.notifier).markSucceeded();
      if (ref.read(collectionPaymentContextProvider) != null) {
        ref.read(posOnlineOrderCollectionProvider.notifier)
            .markPaymentSettled(saleId: payload.saleId);
        ref.read(collectionPaymentContextProvider.notifier).state = null;
        ref.read(posCashPaymentIntentProvider.notifier).clear();
        context.go('/pos/online-orders/collection/payment-success');
        return;
      }
      ref.read(posNewSaleCartProvider.notifier).completeSale(payload.saleId);
      // No automatic drawer pulse/print during reconciliation: physical delivery
      // may already have happened. The authoritative receipt remains available.
      context.go('/pos/new-sale/payment/cash/success');
    } on Object {
      if (mounted) {
        _showSnackBar(context,
            'Unable to confirm payment status. Check again when connected.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CheckoutErrorFallback extends StatelessWidget {
  const _CheckoutErrorFallback({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: TenantAdminColors.warning,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              'Cash payment unavailable',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TenantAdminTextStyles.muted(context),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Back'),
                ),
                const SizedBox(width: TenantAdminSpacing.sm),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCartFallback extends StatelessWidget {
  const _EmptyCartFallback({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: TenantAdminColors.mutedText,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            'No items in cart',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          FilledButton(
            onPressed: onBack,
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
