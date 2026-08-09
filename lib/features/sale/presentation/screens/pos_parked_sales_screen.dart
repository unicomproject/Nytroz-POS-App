import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../cart/presentation/providers/pos_parked_sale_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../widgets/new_sale/parked_sales/parked_sale_summary_panel.dart';
import '../widgets/new_sale/pos_parked_sales_panel.dart';

/// Home Parked Sales screen (`/pos/parked-sales`).
///
/// Renders the same list body used by the New Sale Parked Sales dialog, but
/// as a full page. Recall/cancel actions and permission checks live in
/// [PosParkedSalesPanel]; this screen only decides what happens after a
/// successful recall.
class PosParkedSalesScreen extends ConsumerWidget {
  const PosParkedSalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(posParkedSaleProvider);
    final notifier = ref.read(posParkedSaleProvider.notifier);
    final access = ref.watch(posParkedSaleAccessContextProvider);

    return Semantics(
      container: true,
      label: 'Parked sales screen',
      child: ColoredBox(
        color: TenantAdminColors.surface,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final summary = ParkedSaleSummaryPanel(
              key: const ValueKey('dashboard-parked-sales-summary'),
              totalCount: notifier.totalCount,
              totalValue: notifier.totalValue,
              currency: notifier.currency,
              canStartSale:
                  PosPermissionAccess.canAccessNewSale(access.permissions),
            );
            const list = PosParkedSalesPanel(
              key: ValueKey('pos-parked-sales-screen'),
              onRecallSuccess: _onRecallSuccess,
            );

            if (constraints.maxWidth < 1000) {
              return list;
            }

            return Row(
              children: [
                const Expanded(child: list),
                SizedBox(width: 300, child: summary),
              ],
            );
          },
        ),
      ),
    );
  }

  static void _onRecallSuccess(
    BuildContext context,
    WidgetRef ref,
    PosParkedSale sale,
  ) {
    if (!context.mounted) {
      return;
    }
    // The cart was already restored by PosParkedSaleNotifier.recall(); the
    // active cart lives on the New Sale screen, so navigate there.
    GoRouter.of(context).go('/pos/new-sale');
  }
}
