import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../core/access/pos_permission_access.dart';
import '../../domain/entities/pos_checkout_api_exception.dart';
import '../../domain/entities/pos_payment_method_type.dart';
import '../providers/pos_checkout_summary_provider.dart';
import '../widgets/payment_method/pages/payment_method_page.dart';

class PosPaymentMethodScreen extends ConsumerStatefulWidget {
  const PosPaymentMethodScreen({super.key});

  @override
  ConsumerState<PosPaymentMethodScreen> createState() =>
      _PosPaymentMethodScreenState();
}

class _PosPaymentMethodScreenState
    extends ConsumerState<PosPaymentMethodScreen> {
  PosPaymentMethodType? _selectedMethod;
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posNewSaleCartProvider);
    final session = ref.watch(authSessionProvider);
    final summaryAsync = ref.watch(posCheckoutSummaryProvider);

    if (!PosPermissionAccess.canAccessPaymentMethodScreenSession(session)) {
      return const TenantAdminForbiddenScreen();
    }
    if (!cart.hasItems) {
      return _MessageState(
        icon: Icons.shopping_cart_outlined,
        title: 'No items in cart',
        message: 'Add products before proceeding to payment.',
        actionLabel: 'Back to Cart',
        onAction: context.pop,
      );
    }

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        final expired = error is PosCheckoutApiException &&
            error.code == 'pos_checkout.discount_application_expired';
        return _MessageState(
          icon: Icons.error_outline_rounded,
          title: 'Checkout unavailable',
          message: error is PosCheckoutApiException
              ? error.message
              : 'Unable to load checkout summary.',
          actionLabel: expired ? 'Remove Discount & Retry' : 'Retry',
          onAction: () {
            if (expired) {
              ref.read(posNewSaleCartProvider.notifier).clearDiscounts();
            }
            ref.invalidate(posCheckoutSummaryProvider);
          },
        );
      },
      data: (summary) {
        final methods = summary.paymentMethods.toSet();
        return PaymentMethodPage(
          summary: summary,
          cart: cart,
          allowedMethods: methods,
          selectedMethod: _selectedMethod,
          isNavigating: _isNavigating,
          onSelectMethod: (method) {
            if (method == PosPaymentMethodType.cash) {
              setState(() => _selectedMethod = method);
            }
          },
          onContinue: _selectedMethod == PosPaymentMethodType.cash &&
                  !summary.usedFallback &&
                  methods.contains(PosPaymentMethodType.cash)
              ? () => _continueToCash(
                    session?.permissionCodes.toSet() ?? const {},
                    summary,
                  )
              : null,
        );
      },
    );
  }

  Future<void> _continueToCash(
    Set<String> permissions,
    PosCheckoutSummaryViewData summary,
  ) async {
    if (_isNavigating || _selectedMethod != PosPaymentMethodType.cash) return;
    if (summary.usedFallback ||
        !PosPermissionAccess.canContinueWithPaymentPermission(
          permissions,
          PosPaymentMethodType.cash.permissionCode,
        )) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'Cash payment is not available for this sale.',
      );
      return;
    }
    setState(() => _isNavigating = true);
    try {
      await context.push(PosPaymentMethodType.cash.paymentRoutePath);
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: TenantAdminColors.warning),
            const SizedBox(height: 16),
            Text(title, style: TenantAdminTextStyles.sectionTitle(context)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ]),
        ),
      );
}
