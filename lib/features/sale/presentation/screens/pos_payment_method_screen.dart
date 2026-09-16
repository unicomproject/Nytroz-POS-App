import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../fulfilment_pickup/presentation/providers/pos_online_order_collection_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../core/access/permission_access_providers.dart';
import '../../../../core/access/pos_permission_access.dart';
import '../../../../core/access/pos_payment_permission_visibility.dart';
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

  PosCheckoutSummaryViewData _collectionSummary(
    CollectionPaymentContext collection,
    AuthSession? session,
  ) {
    return PosCheckoutSummaryViewData(
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
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posNewSaleCartProvider);
    final session = ref.watch(authSessionProvider);
    final permissions = ref.watch(effectivePermissionSetProvider);
    final collection = ref.watch(collectionPaymentContextProvider);
    final summaryAsync = ref.watch(posCheckoutSummaryProvider);

    if (!PosPermissionAccess.canAccessPaymentMethodScreenSession(session)) {
      return const TenantAdminForbiddenScreen();
    }
    if (!cart.hasItems && collection == null) {
      return _MessageState(
        icon: Icons.shopping_cart_outlined,
        title: 'No items in cart',
        message: 'Add products before proceeding to payment.',
        actionLabel: 'Back to Cart',
        onAction: context.pop,
      );
    }

    if (collection != null) {
      final summary = _collectionSummary(collection, session);
      final methods = summary.paymentMethods
          .where(
            (m) => PosPaymentPermissionVisibility.canShowMethod(
              permissions,
              m,
            ),
          )
          .toSet();
      return PaymentMethodPage(
        summary: summary,
        cart: cart,
        allowedMethods: methods,
        selectedMethod:
            methods.contains(_selectedMethod) ? _selectedMethod : null,
        isNavigating: _isNavigating,
        onSelectMethod: (method) {
          setState(() => _selectedMethod = method);
        },
        onContinue: _selectedMethod != null && methods.contains(_selectedMethod)
            ? () => _continueToPayment(
                  session?.permissionCodes.toSet() ?? const {},
                  summary,
                )
            : null,
        onCustomerTap: null,
        onBackToSale: () {
          ref.read(collectionPaymentContextProvider.notifier).state = null;
          context.go('/pos/online-orders/collection/verification');
        },
      );
    }

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        final discountNeedsReapply = error is PosCheckoutApiException &&
            (error.code == 'pos_checkout.discount_application_expired' ||
                error.code == 'pos_checkout.discount_cart_changed' ||
                error.code == 'pos_checkout.discount_context_mismatch' ||
                error.code == 'pos_checkout.discount_application_invalid');
        return _MessageState(
          icon: Icons.error_outline_rounded,
          title: 'Checkout unavailable',
          message: error is PosCheckoutApiException
              ? _checkoutUnavailableMessage(error)
              : 'Unable to load checkout summary.',
          actionLabel:
              discountNeedsReapply ? 'Remove Discount & Retry' : 'Retry',
          onAction: () {
            if (discountNeedsReapply) {
              ref.read(posNewSaleCartProvider.notifier).clearDiscounts();
            }
            ref.invalidate(posCheckoutSummaryProvider);
          },
        );
      },
      data: (summary) {
        final methods = summary.paymentMethods
            .where(
              (m) => PosPaymentPermissionVisibility.canShowMethod(
                permissions,
                m,
              ),
            )
            .toSet();
        if (_selectedMethod != null && !methods.contains(_selectedMethod)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                _selectedMethod != null &&
                !methods.contains(_selectedMethod)) {
              setState(() => _selectedMethod = null);
            }
          });
        }
        return PaymentMethodPage(
          summary: summary,
          cart: cart,
          allowedMethods: methods,
          selectedMethod:
              methods.contains(_selectedMethod) ? _selectedMethod : null,
          isNavigating: _isNavigating,
          onSelectMethod: (method) {
            setState(() => _selectedMethod = method);
          },
          onContinue: _selectedMethod != null &&
                  !summary.usedFallback &&
                  methods.contains(_selectedMethod)
              ? () => _continueToPayment(
                    session?.permissionCodes.toSet() ?? const {},
                    summary,
                  )
              : null,
          onCustomerTap: PosPermissionAccess.hasAny(
            session?.permissionCodes.toSet() ?? const {},
            PosPermissionAccess.customerViewOrCreateAccessCodes,
          )
              ? () => context.push('/pos/new-sale/payment/customer')
              : () => PosPermissionAccess.showAccessDeniedSnackBar(
                    context,
                    'Customer access is not available for this account.',
                  ),
        );
      },
    );
  }

  Future<void> _continueToPayment(
    Set<String> permissions,
    PosCheckoutSummaryViewData summary,
  ) async {
    final selectedMethod = _selectedMethod;
    if (_isNavigating || selectedMethod == null) return;
    if (summary.usedFallback ||
        !summary.paymentMethods.contains(selectedMethod) ||
        !PosPermissionAccess.canContinueWithPaymentPermission(
          permissions,
          selectedMethod.permissionCode,
        )) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        '${selectedMethod.title} is not available for this sale.',
      );
      return;
    }
    setState(() => _isNavigating = true);
    try {
      await context.push(selectedMethod.paymentRoutePath);
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }
}

String _checkoutUnavailableMessage(PosCheckoutApiException error) {
  return switch (error.code) {
    'pos_checkout.discount_cart_changed' ||
    'pos_checkout.discount_context_mismatch' =>
      'The discount no longer matches this cart or customer. '
          'Remove the discount and apply it again, or retry after refreshing.',
    'pos_checkout.discount_application_expired' =>
      'The discount approval has expired. Remove the discount and try again.',
    'pos_checkout.discount_application_invalid' =>
      'The applied discount is no longer valid. Remove it and apply again.',
    _ => error.message,
  };
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
