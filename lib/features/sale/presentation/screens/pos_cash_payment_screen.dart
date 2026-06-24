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
import '../providers/pos_cash_payment_provider.dart';
import '../providers/pos_cash_payment_success_provider.dart';
import '../providers/pos_checkout_summary_provider.dart';
import '../widgets/cash_payment/cash_payment_bottom_actions.dart';
import '../widgets/cash_payment/cash_payment_header.dart';
import '../widgets/cash_payment/cash_payment_right_panel.dart';
import '../widgets/cash_payment/cash_received_section.dart';
import '../widgets/cash_payment/cash_sale_summary_card.dart';

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
            final useWideLayout =
                constraints.maxWidth >= TenantAdminBreakpoints.tablet;

            return Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CashPaymentHeader(onBack: () => context.pop()),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Expanded(
                    child: useWideLayout
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    CashSaleSummaryCard(
                                      itemCount: summary.itemCount,
                                      subtotal: summary.subtotal,
                                      discount: summary.discount,
                                      tax: summary.tax,
                                      total: total,
                                    ),
                                    const SizedBox(
                                        height: TenantAdminSpacing.lg),
                                    Expanded(
                                      child: CashReceivedSection(
                                        total: total,
                                        cashReceived: cashReceived,
                                        inputBuffer: cashState.inputBuffer,
                                        onClear: () => ref
                                            .read(
                                                posCashPaymentProvider.notifier)
                                            .clearAmount(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: TenantAdminSpacing.lg),
                              Expanded(
                                flex: 2,
                                child: CashPaymentRightPanel(
                                  total: total,
                                  cashReceived: cashReceived,
                                  onKeyTap: onKeyTap,
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CashSaleSummaryCard(
                                  itemCount: summary.itemCount,
                                  subtotal: summary.subtotal,
                                  discount: summary.discount,
                                  tax: summary.tax,
                                  total: total,
                                ),
                                const SizedBox(height: TenantAdminSpacing.lg),
                                CashReceivedSection(
                                  total: total,
                                  cashReceived: cashReceived,
                                  inputBuffer: cashState.inputBuffer,
                                  onClear: () => ref
                                      .read(posCashPaymentProvider.notifier)
                                      .clearAmount(),
                                ),
                                const SizedBox(height: TenantAdminSpacing.lg),
                                SizedBox(
                                  height: 520,
                                  child: CashPaymentRightPanel(
                                    total: total,
                                    cashReceived: cashReceived,
                                    onKeyTap: onKeyTap,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  CashPaymentBottomActions(
                    canConfirm: canConfirm,
                    isLoading: _isSubmitting,
                    onBack: () => context.pop(),
                    onConfirm: () => _confirmCashPayment(context, summary),
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

    setState(() => _isSubmitting = true);

    try {
      final payload =
          await ref.read(posCheckoutRemoteDatasourceProvider).startPayment(
                deviceId: deviceContext.deviceId,
                paymentMethod:
                    checkoutApiPaymentMethodCode(PosPaymentMethodType.cash),
                lines: checkoutLinesFromCart(cart),
                cashReceived: cashReceived,
              );

      ref
          .read(posCashPaymentSuccessProvider.notifier)
          .recordCheckoutPayment(payload);
    } on PosCheckoutApiException catch (error) {
      if (!context.mounted) {
        return;
      }
      _showSnackBar(context, error.message);
      return;
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    if (!context.mounted) {
      return;
    }

    context.push('/pos/new-sale/payment/cash/success');
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
