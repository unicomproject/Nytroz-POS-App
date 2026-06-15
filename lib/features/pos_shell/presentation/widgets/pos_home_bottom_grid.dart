import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/pos_home_action.dart';
import 'pos_cash_drawer_summary_card.dart';
import 'pos_customer_summary_card.dart';
import 'pos_parked_sales_summary_card.dart';
import 'pos_returns_summary_card.dart';

class PosHomeBottomGrid extends StatelessWidget {
  const PosHomeBottomGrid({
    super.key,
    required this.returnsAction,
    required this.customerAction,
    required this.parkedSalesAction,
    required this.cashDrawerAction,
    required this.showReturns,
    required this.showCustomer,
    required this.showParkedSales,
    required this.showCashDrawer,
  });

  final PosHomeAction returnsAction;
  final PosHomeAction customerAction;
  final PosHomeAction parkedSalesAction;
  final PosHomeAction cashDrawerAction;
  final bool showReturns;
  final bool showCustomer;
  final bool showParkedSales;
  final bool showCashDrawer;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (showReturns) PosReturnsSummaryCard(action: returnsAction),
      if (showCustomer) PosCustomerSummaryCard(action: customerAction),
      if (showParkedSales) PosParkedSalesSummaryCard(action: parkedSalesAction),
      if (showCashDrawer) PosCashDrawerSummaryCard(action: cashDrawerAction),
    ];

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = _columnCountFor(constraints.maxWidth, cards.length);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: TenantAdminSpacing.lg,
            mainAxisSpacing: TenantAdminSpacing.lg,
            mainAxisExtent: 320,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

int _columnCountFor(double width, int itemCount) {
  if (itemCount == 1) {
    return 1;
  }

  if (width < 520) {
    return 1;
  }

  if (width < 820) {
    return itemCount >= 2 ? 2 : 1;
  }

  return itemCount >= 4 ? 4 : itemCount;
}
