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
  final bool isStartSaleEnabled;
  final String? startSaleDisabledMessage;
  final VoidCallback? onStartSale;
  final VoidCallback? onViewOrders;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < TenantAdminBreakpoints.tablet;
        final hero = PosStartSaleHeroCard(
          title: startSaleTitle,
          description: startSaleDescription,
          buttonLabel: startSaleButtonLabel,
          isEnabled: isStartSaleEnabled && startSaleAction.routeExists,
          disabledMessage: startSaleDisabledMessage,
          onStartSale: onStartSale,
        );
        final onlineOrders = PosOnlineOrdersSummaryCard(
          action: onlineOrdersAction,
          onViewOrders: onViewOrders,
        );

        if (isStacked) {
          return Column(
            children: [
              hero,
              const SizedBox(height: TenantAdminSpacing.lg),
              SizedBox(height: 330, child: onlineOrders),
            ],
          );
        }

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
      },
    );
  }
}
