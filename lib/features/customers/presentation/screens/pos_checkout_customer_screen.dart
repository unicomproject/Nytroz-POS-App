import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../pos/presentation/widgets/new_sale/navigation/pos_cashier_bottom_navigation.dart';
import '../../../pos_shell/presentation/widgets/common/pos_top_bar.dart';
import '../../../pos_shell/presentation/widgets/common/pos_top_bar_notification_button.dart';
import '../../../pos_shell/presentation/widgets/home/pos_dashboard_top_bar_content.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/checkout_customer_provider.dart';
import '../widgets/checkout_customer/checkout_customer_content.dart';
import '../widgets/checkout_customer/checkout_customer_header.dart';

class PosCheckoutCustomerScreen extends ConsumerWidget {
  const PosCheckoutCustomerScreen({super.key, this.showChrome = true});
  final bool showChrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutCustomerProvider);
    final notifier = ref.read(checkoutCustomerProvider.notifier);
    final permissions =
        ref.watch(authSessionProvider)?.permissionCodes.toSet() ??
            const <String>{};
    final canView = PosPermissionAccess.canViewCustomers(permissions);
    final canCreate = PosPermissionAccess.canCreateCustomer(permissions);
    final canAttach =
        PosPermissionAccess.canAttachCustomerToSale(permissions);

    Future<void> advanceToPayment(Future<bool> Function() action) async {
      final success = await action();
      if (!success || !context.mounted) return;
      final path = GoRouterState.of(context).uri.path;
      if (path == '/pos/new-sale/payment/customer') {
        context.pop();
      } else {
        context.push('/pos/new-sale/payment');
      }
    }

    void handleBack() {
      if (context.mounted) {
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          context.go('/pos/new-sale');
        }
      }
    }

    if (!canView) {
      return _Shell(
        showChrome: showChrome,
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          child: Column(
            children: [
              CheckoutCustomerHeader(
                isCreateMode: false,
                onBack: handleBack,
                onSkip: () => advanceToPayment(notifier.skip),
              ),
              const Expanded(
                child: Center(
                  key: ValueKey('checkout-customer-permission-denied'),
                  child: Text(
                    'Customer search is unavailable. You can continue as a walk-in customer.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _Shell(
      showChrome: showChrome,
      child: CheckoutCustomerContent(
        state: state,
        canCreate: canCreate,
        canAttach: canAttach,
        onDigit: notifier.enterDigit,
        onBackspace: notifier.backspace,
        onClear: notifier.clearPhone,
        onDialCodeChanged: notifier.setDialCode,
        onRetrySearch: notifier.search,
        onConfirmFound: () => advanceToPayment(notifier.confirmFound),
        onBeginCreate: notifier.beginCreate,
        onNameChanged: notifier.setCustomerName,
        onChangeNumber: notifier.changeNumber,
        onCreate: () => advanceToPayment(notifier.createAndContinue),
        onBack: handleBack,
        onSkip: () => advanceToPayment(notifier.skip),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.showChrome, required this.child});
  final bool showChrome;
  final Widget child;
  @override
  Widget build(BuildContext context) => ColoredBox(
        key: const ValueKey('checkout-customer-screen'),
        color: TenantAdminColors.background,
        child: Column(children: [
          if (showChrome)
            const PosTopBar(
                content: PosDashboardTopBarContent(),
                trailing: PosTopBarNotificationButton(dark: true)),
          Expanded(child: child),
          if (showChrome) const PosCashierBottomNavigation(),
        ]),
      );
}
