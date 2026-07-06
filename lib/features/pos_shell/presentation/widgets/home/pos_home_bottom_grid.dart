import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/pos_home_action.dart';
import 'pos_cash_drawer_summary_card.dart';
import 'pos_customer_summary_card.dart';
import 'pos_parked_sales_summary_card.dart';
import '../pos_returns_summary_card.dart';

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
    this.onViewReturns,
    this.onAddCustomer,
    this.onViewParkedSales,
    this.onViewCashDrawer,
  });

  final PosHomeAction returnsAction;
  final PosHomeAction customerAction;
  final PosHomeAction parkedSalesAction;
  final PosHomeAction cashDrawerAction;
  final bool showReturns;
  final bool showCustomer;
  final bool showParkedSales;
  final bool showCashDrawer;
  final VoidCallback? onViewReturns;
  final VoidCallback? onAddCustomer;
  final VoidCallback? onViewParkedSales;
  final VoidCallback? onViewCashDrawer;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (showReturns)
        PosReturnsSummaryCard(
          action: returnsAction,
          onViewReturns: onViewReturns,
        ),
      if (showCustomer)
        PosCustomerSummaryCard(
          action: customerAction,
          onAddCustomer: onAddCustomer,
        ),
      if (showParkedSales)
        PosParkedSalesSummaryCard(
          action: parkedSalesAction,
          onViewParkedSales: onViewParkedSales,
        ),
      if (showCashDrawer)
        PosCashDrawerSummaryCard(
          action: cashDrawerAction,
          onViewCashDrawer: onViewCashDrawer,
        ),
    ];

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = _columnCountFor(constraints.maxWidth, cards.length);
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final rowCount = (cards.length / columnCount).ceil();
        final availableSpacing =
            TenantAdminSpacing.lg * (rowCount - 1).clamp(0, rowCount);
        final itemExtent = hasBoundedHeight
            ? ((constraints.maxHeight - availableSpacing) / rowCount)
                .clamp(_minimumCardHeight, _maximumCardHeight)
            : _comfortableCardHeight;

        return GridView.builder(
          shrinkWrap: !hasBoundedHeight,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: TenantAdminSpacing.lg,
            mainAxisSpacing: TenantAdminSpacing.lg,
            mainAxisExtent: itemExtent,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

const _minimumCardHeight = 230.0;
const _comfortableCardHeight = 260.0;
const _maximumCardHeight = 340.0;
const _fourColumnMinimumWidth = 1040.0;

int _columnCountFor(double width, int itemCount) {
  if (itemCount == 1) {
    return 1;
  }

  if (width < TenantAdminBreakpoints.mobile) {
    return 1;
  }

  if (width < _fourColumnMinimumWidth) {
    return itemCount < 2 ? itemCount : 2;
  }

  return itemCount < 4 ? itemCount : 4;
}
