import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/pos_home_action.dart';
import 'pos_online_orders_summary_card.dart';
import 'pos_start_sale_hero_card.dart';

class PosHomeTopGrid extends StatelessWidget {
  const PosHomeTopGrid({
    super.key,
    required this.startSaleAction,
    required this.onlineOrdersAction,
    required this.startSaleTitle,
    required this.startSaleDescription,
    required this.startSaleButtonLabel,
    required this.showStartSale,
    required this.showOnlineOrders,
    required this.isStartSaleEnabled,
    this.startSaleDisabledMessage,
    this.onStartSale,
    this.onViewOrders,
  });

  final PosHomeAction startSaleAction;
  final PosHomeAction onlineOrdersAction;
  final String startSaleTitle;
  final String startSaleDescription;
  final String startSaleButtonLabel;
  final bool showStartSale;
  final bool showOnlineOrders;
  final bool isStartSaleEnabled;
  final String? startSaleDisabledMessage;
  final VoidCallback? onStartSale;
  final VoidCallback? onViewOrders;

  @override
  Widget build(BuildContext context) {
    if (!showStartSale && !showOnlineOrders) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < TenantAdminBreakpoints.tablet;
        final hero = showStartSale
            ? PosStartSaleHeroCard(
                title: startSaleTitle,
                description: startSaleDescription,
                buttonLabel: startSaleButtonLabel,
                isEnabled: isStartSaleEnabled && startSaleAction.routeExists,
                disabledMessage: startSaleDisabledMessage ??
                    (startSaleAction.routeExists
                        ? null
                        : 'Destination is not available yet.'),
                onStartSale: onStartSale,
              )
            : null;
        final onlineOrders = showOnlineOrders
            ? PosOnlineOrdersSummaryCard(
                action: onlineOrdersAction,
                onViewOrders: onViewOrders,
              )
            : null;

        if (isStacked) {
          return Column(
            children: [
              if (hero != null) hero,
              if (hero != null && onlineOrders != null)
                const SizedBox(height: TenantAdminSpacing.lg),
              if (onlineOrders != null)
                SizedBox(height: 330, child: onlineOrders),
            ],
          );
        }

        if (hero != null && onlineOrders != null) {
          return SizedBox(
            height: 330,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: hero),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(flex: 4, child: onlineOrders),
              ],
            ),
          );
        }

        if (hero != null) {
          return SizedBox(height: 330, child: hero);
        }

        return SizedBox(height: 330, child: onlineOrders);
      },
    );
  }
}
