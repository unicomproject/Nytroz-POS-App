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
  });

  final PosHomeAction returnsAction;
  final PosHomeAction customerAction;
  final PosHomeAction parkedSalesAction;
  final PosHomeAction cashDrawerAction;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      PosReturnsSummaryCard(action: returnsAction),
      PosCustomerSummaryCard(action: customerAction),
      PosParkedSalesSummaryCard(action: parkedSalesAction),
      PosCashDrawerSummaryCard(action: cashDrawerAction),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = _columnCountFor(constraints.maxWidth);

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

int _columnCountFor(double width) {
  if (width < 520) {
    return 1;
  }

  if (width < 820) {
    return 2;
  }

  return 4;
}
