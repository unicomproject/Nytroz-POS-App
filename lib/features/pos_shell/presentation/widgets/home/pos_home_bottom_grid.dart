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
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final cardRow = _QuickActionCardRow(cards: cards);

        if (!hasBoundedHeight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuickActionsHeading(context: context),
              const SizedBox(height: TenantAdminSpacing.md),
              cardRow,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QuickActionsHeading(context: context),
            const SizedBox(height: TenantAdminSpacing.md),
            Expanded(child: cardRow),
          ],
        );
      },
    );
  }
}

class _QuickActionsHeading extends StatelessWidget {
  const _QuickActionsHeading({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Text(
      'Quick Actions',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _QuickActionCardRow extends StatelessWidget {
  const _QuickActionCardRow({required this.cards});

  final List<Widget> cards;

  static const _minSquareSize = 118.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = TenantAdminSpacing.md * (cards.length - 1);
        final cardWidth = (constraints.maxWidth - spacing) / cards.length;
        final fitsSingleRowSquares = cardWidth >= _minSquareSize;

        if (fitsSingleRowSquares) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                if (index > 0) const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: cards[index],
                  ),
                ),
              ],
            ],
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                if (index > 0) const SizedBox(width: TenantAdminSpacing.md),
                SizedBox(
                  width: _minSquareSize,
                  height: _minSquareSize,
                  child: cards[index],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
