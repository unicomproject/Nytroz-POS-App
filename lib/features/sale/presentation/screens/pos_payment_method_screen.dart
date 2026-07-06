import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/pos_checkout_api_exception.dart';
import '../../domain/entities/pos_payment_method_type.dart';
import '../providers/pos_checkout_summary_provider.dart';
import '../widgets/payment/payment_action_bar.dart';
import '../widgets/payment/payment_billing_summary_card.dart';
import '../widgets/payment/payment_method_card.dart';
import '../widgets/payment/payment_sale_details_card.dart';

class PosPaymentMethodScreen extends ConsumerWidget {
  const PosPaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(posNewSaleCartProvider);
    final session = ref.watch(authSessionProvider);
    final grantedPermissions = session?.permissionCodes.toSet() ?? const {};
    final summaryAsync = ref.watch(posCheckoutSummaryProvider);

    if (!PosPermissionAccess.canAccessPaymentMethodScreenSession(session)) {
      return const TenantAdminForbiddenScreen();
    }

    if (!cart.hasItems) {
      return _EmptyCartFallback(onBack: () => context.pop());
    }

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _CheckoutErrorFallback(
        message: _messageForCheckoutError(error),
        onBack: () => context.pop(),
        onRetry: () => ref.invalidate(posCheckoutSummaryProvider),
      ),
      data: (summary) {
        final allowedMethods = summary.paymentMethods;

        return LayoutBuilder(
          builder: (context, constraints) {
            final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);
            final useSideBySide =
                constraints.maxWidth >= TenantAdminBreakpoints.tablet;

            return Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PaymentScreenHeader(onBack: () => context.pop()),
                  if (summary.usedFallback) ...[
                    const SizedBox(height: TenantAdminSpacing.md),
                    _CheckoutFallbackBanner(
                      message: summary.fallbackMessage ??
                          checkoutFallbackUnavailableMessage,
                    ),
                  ],
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Expanded(
                    child: useSideBySide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _LeftPanel(summary: summary),
                              ),
                              const SizedBox(width: TenantAdminSpacing.lg),
                              Expanded(
                                flex: 3,
                                child: _PaymentMethodPanel(
                                  allowedMethods: allowedMethods,
                                  canNavigate: !summary.usedFallback,
                                  onMethodTap: (method) => _onPaymentMethodTap(
                                    context,
                                    grantedPermissions,
                                    summary,
                                    method,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LeftPanel(summary: summary),
                                const SizedBox(height: TenantAdminSpacing.lg),
                                SizedBox(
                                  height: 360,
                                  child: _PaymentMethodPanel(
                                    allowedMethods: allowedMethods,
                                    canNavigate: !summary.usedFallback,
                                    onMethodTap: (method) => _onPaymentMethodTap(
                                      context,
                                      grantedPermissions,
                                      summary,
                                      method,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  PaymentActionBar(
                    continueLabel: '',
                    onBackToCart: () => context.pop(),
                    onContinue: null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onPaymentMethodTap(
    BuildContext context,
    Set<String> grantedPermissions,
    PosCheckoutSummaryViewData summary,
    PosPaymentMethodType method,
  ) {
    if (summary.usedFallback) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Checkout validation is unavailable. Cannot proceed to payment.',
            ),
          ),
        );
      return;
    }

    if (!PosPermissionAccess.canContinueWithPaymentPermission(
      grantedPermissions,
      method.permissionCode,
    )) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'You do not have permission to use this payment method.',
      );
      return;
    }

    context.push(method.paymentRoutePath);
  }
}

String _messageForCheckoutError(Object error) {
  if (error is PosCheckoutApiException) {
    return error.message;
  }

  return 'Unable to load checkout summary.';
}

class _CheckoutFallbackBanner extends StatelessWidget {
  const _CheckoutFallbackBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: TenantAdminColors.warning,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
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
              'Checkout unavailable',
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
                  child: const Text('Back to Cart'),
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

class _PaymentScreenHeader extends StatelessWidget {
  const _PaymentScreenHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onBack,
          tooltip: 'Back to cart',
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: TenantAdminColors.surface,
            side: const BorderSide(color: TenantAdminColors.border),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: TenantAdminTextStyles.pageTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                'Complete the payment for this sale',
                style: TenantAdminTextStyles.muted(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({required this.summary});

  final PosCheckoutSummaryViewData summary;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaymentBillingSummaryCard(
            itemCount: summary.itemCount,
            subtotal: summary.subtotal,
            discount: summary.discount,
            tax: summary.tax,
            totalPayable: summary.totalPayable,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          PaymentSaleDetailsCard(
            saleType: summary.saleType,
            itemCount: summary.itemsInCart,
            cashierName: summary.cashierName,
            saleDate: _formatSaleDate(summary.saleDate),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodPanel extends StatelessWidget {
  const _PaymentMethodPanel({
    required this.allowedMethods,
    required this.canNavigate,
    required this.onMethodTap,
  });

  final List<PosPaymentMethodType> allowedMethods;
  final bool canNavigate;
  final ValueChanged<PosPaymentMethodType> onMethodTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Payment Method',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            if (allowedMethods.isEmpty)
              const Expanded(child: _NoPaymentMethodsMessage())
            else
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: TenantAdminSpacing.md,
                    mainAxisSpacing: TenantAdminSpacing.md,
                    childAspectRatio: 1.45,
                  ),
                  itemCount: allowedMethods.length,
                  itemBuilder: (context, index) {
                    final method = allowedMethods[index];
                    return PaymentMethodCard(
                      method: method,
                      onTap: canNavigate ? () => onMethodTap(method) : () {},
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoPaymentMethodsMessage extends StatelessWidget {
  const _NoPaymentMethodsMessage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 40,
          color: TenantAdminColors.mutedText,
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Text(
          'No payment methods available',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'You do not have permission to accept any payment methods.',
          style: TenantAdminTextStyles.muted(context),
        ),
      ],
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
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'Add products on the New Sale screen before proceeding to payment.',
            textAlign: TextAlign.center,
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          FilledButton(
            onPressed: onBack,
            child: const Text('Back to Cart'),
          ),
        ],
      ),
    );
  }
}

String _formatSaleDate(DateTime value) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${weekdays[value.weekday - 1]}, ${months[value.month - 1]} '
      '${value.day}, ${value.year}';
}
