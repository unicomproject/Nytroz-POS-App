import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/pos_checkout_api_exception.dart';
import '../../domain/entities/pos_payment_method_type.dart';
import '../providers/pos_cash_payment_intent_provider.dart';
import '../providers/pos_cash_payment_provider.dart';
import '../providers/pos_cash_payment_success_provider.dart';
import '../providers/pos_checkout_summary_provider.dart';
import '../../../hardware/receipt_printer/presentation/providers/cash_drawer_controller.dart';
import '../widgets/cash_payment/cash_payment_screen_body.dart';

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
    final summaryAsync = ref.watch(posCheckoutSummaryProvider);
    final cashState = ref.watch(posCashPaymentProvider);

    if (!PosPermissionAccess.canAccessCashPaymentScreenSession(session)) {
      return const TenantAdminForbiddenScreen();
    }

    if (!cart.hasItems) {
      return _EmptyCartFallback(onBack: () => context.pop());
    }

    return summaryAsync.when(
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
            message:
                summary.fallbackMessage ?? checkoutFallbackUnavailableMessage,
            onBack: () => context.pop(),
            onRetry: () => ref.invalidate(posCheckoutSummaryProvider),
          );
        }

        final total = summary.totalPayable;
        final cashReceived = cashState.cashReceived;
        final canConfirm = canConfirmCashPayment(cashReceived, total);
        final onKeyTap = ref.read(posCashPaymentProvider.notifier).appendKey;

        return LayoutBuilder(
          builder: (context, constraints) {
            final padding =
                TenantAdminInsets.pageForWidth(constraints.maxWidth);

            return Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: CashPaymentScreenBody(
                      itemCount: summary.itemCount,
                      subtotal: summary.subtotal,
                      discount: summary.discount,
                      tax: summary.tax,
                      totalDue: total,
                      items: cart.itemList,
                      cashReceived: cashReceived,
                      inputBuffer: cashState.inputBuffer,
                      quickAmounts: generateCashQuickAmounts(total),
                      selectedQuickAmount: cashState.selectedQuickAmount,
                      onQuickAmountSelected: (amount) => ref
                          .read(posCashPaymentProvider.notifier)
                          .setAmount(amount, selectedQuickAmount: amount),
                      onOtherAmountPressed: () {},
                      onDigitPressed: onKeyTap,
                      onDoubleZeroPressed: () => onKeyTap('00'),
                      onBackspacePressed: () => onKeyTap('backspace'),
                      onClearPressed: () => ref
                          .read(posCashPaymentProvider.notifier)
                          .clearAmount(),
                      isSubmitting: _isSubmitting,
                      canCompleteSale: canConfirm,
                      onExactCashPressed: () {
                        ref
                            .read(posCashPaymentProvider.notifier)
                            .setAmount(total, selectedQuickAmount: total);
                      },
                      onCompleteSalePressed: () =>
                          _confirmCashPayment(context, summary),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmCashPayment(
    BuildContext context,
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
    if (cart.itemList.isEmpty) {
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
    final saleIdentity = cart.itemList
        .map((i) => '${i.product.variantId}:${i.quantity}')
        .join('|');
    final requestFingerprint = '$saleIdentity|cash=$cashReceived';

    // Obtain the stable idempotency key from the intent state machine.
    // beginSubmission returns the same intent if already in-flight with
    // the same fingerprint (prevents duplicate network requests).
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
      final payload =
          await ref.read(posCheckoutRemoteDatasourceProvider).startPayment(
                deviceId: deviceContext.deviceId,
                paymentMethod:
                    checkoutApiPaymentMethodCode(PosPaymentMethodType.cash),
                lines: checkoutLinesFromCart(cart),
                cashReceived: cashReceived,
                customerId: cart.selectedCustomer?.customerId,
                discountApplicationId: cart.discountApplicationId,
                idempotencyKey: intent.key,
              );

      // Mark the intent succeeded — prevents resubmission.
      ref.read(posCashPaymentIntentProvider.notifier).markSucceeded();

      // Store authoritative backend values (not local preview).
      ref
          .read(posCashPaymentSuccessProvider.notifier)
          .recordCheckoutPayment(payload);

      // Trigger drawer async — isolated from payment success.
      if (payload.drawerOperationId != null &&
          payload.cashDrawerSettings != null) {
        unawaited(
          ref
              .read(cashDrawerControllerProvider.notifier)
              .triggerAutoOpenForCheckout(
                drawerOperationId: payload.drawerOperationId!,
                purposeStr: 'cashSale',
                drawerSettingsJson: payload.cashDrawerSettings!,
                businessReferenceId: payload.saleId,
              ),
        );
      }

      if (!context.mounted) return;

      // Navigate to success only after confirmed backend success.
      context.push('/pos/new-sale/payment/cash/success');
    } on PosCheckoutApiException catch (error) {
      // Distinguish timeout/unknown outcome from confirmed rejections.
      // - Unknown: preserve the same intent key for safe retry.
      // - KnownRejected: require explicit new attempt.
      if (error.isNetworkUnavailable) {
        ref.read(posCashPaymentIntentProvider.notifier).markUnknown();
      } else {
        ref.read(posCashPaymentIntentProvider.notifier).markKnownRejected();
      }

      if (!context.mounted) return;
      _showSnackBar(context, error.message);
      // Cart, entered amount, customer and discount are intentionally preserved.
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
