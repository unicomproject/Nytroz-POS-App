import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/return_create_credit_provider.dart';
import '../../providers/return_receipt_provider.dart';
import '../../providers/return_success_display.dart';
import 'completion_detail_tile.dart';

class CompletionDetailsCard extends StatelessWidget {
  const CompletionDetailsCard({
    super.key,
    required this.display,
  });

  final ReturnSuccessDisplay display;

  @override
  Widget build(BuildContext context) {
    final left = <CompletionDetailTile>[
      CompletionDetailTile(
        icon: Icons.receipt_long_outlined,
        label: display.isExchange ? 'Exchange Reference' : 'Return Reference',
        value: display.reference,
        highlight: true,
      ),
      if (display.returnNumber != null &&
          display.returnNumber!.trim().isNotEmpty &&
          display.isExchange)
        CompletionDetailTile(
          icon: Icons.assignment_return_outlined,
          label: 'Return Reference',
          value: display.returnNumber!.trim(),
        ),
      if (display.originalInvoiceNo != null &&
          display.originalInvoiceNo!.trim().isNotEmpty)
        CompletionDetailTile(
          icon: Icons.receipt_outlined,
          label: 'Original Sale',
          value: display.originalInvoiceNo!.trim(),
        ),
      if (display.replacementOrderNumber != null &&
          display.replacementOrderNumber!.trim().isNotEmpty)
        CompletionDetailTile(
          icon: Icons.shopping_bag_outlined,
          label: 'Replacement Order',
          value: display.replacementOrderNumber!.trim(),
        ),
      if (display.receiptNumber != null &&
          display.receiptNumber!.trim().isNotEmpty)
        CompletionDetailTile(
          icon: Icons.receipt_outlined,
          label: 'Receipt',
          value: display.receiptNumber!.trim(),
        ),
      CompletionDetailTile(
        icon: Icons.person_outline_rounded,
        label: 'Customer',
        value: display.customerName.isEmpty ? '—' : display.customerName,
      ),
      CompletionDetailTile(
        icon: Icons.badge_outlined,
        label: 'Processed By',
        value: display.processedBy.isEmpty ? '—' : display.processedBy,
      ),
      if (display.outletName != null && display.outletName!.trim().isNotEmpty)
        CompletionDetailTile(
          icon: Icons.storefront_outlined,
          label: 'Outlet',
          value: display.outletName!.trim(),
        ),
      if (display.tillName != null && display.tillName!.trim().isNotEmpty)
        CompletionDetailTile(
          icon: Icons.point_of_sale_outlined,
          label: 'Till',
          value: display.tillName!.trim(),
        ),
    ];

    final right = <CompletionDetailTile>[
      if (display.isExchange) ...[
        CompletionDetailTile(
          icon: Icons.swap_horiz_rounded,
          label: display.isEvenExchange ? 'Settlement' : 'Settlement',
          value: display.isEvenExchange ? 'No Settlement' : display.methodLabel,
        ),
        if (display.returnSubtotal != null)
          CompletionDetailTile(
            icon: Icons.list_alt_outlined,
            label: 'Return Subtotal',
            value: formatReturnCreditAmount(
              currency: display.currencyCode,
              amount: display.returnSubtotal!,
            ),
          ),
        if (display.returnDiscount != null && display.returnDiscount! > 0)
          CompletionDetailTile(
            icon: Icons.discount_outlined,
            label: 'Return Discount',
            value: formatReturnCreditAdjustment(
              currency: display.currencyCode,
              amount: display.returnDiscount!,
            ),
          ),
        if (display.returnTax != null)
          CompletionDetailTile(
            icon: Icons.percent_outlined,
            label: 'Return Tax',
            value: formatReturnCreditAmount(
              currency: display.currencyCode,
              amount: display.returnTax!,
            ),
          ),
        if (display.returnItemValue != null)
          CompletionDetailTile(
            icon: Icons.undo_rounded,
            label: 'Return Credit',
            value: formatReturnCreditAmount(
              currency: display.currencyCode,
              amount: display.returnItemValue!,
            ),
          ),
        if (display.replacementSubtotal != null)
          CompletionDetailTile(
            icon: Icons.list_alt_outlined,
            label: 'Replacement Subtotal',
            value: formatReturnCreditAmount(
              currency: display.currencyCode,
              amount: display.replacementSubtotal!,
            ),
          ),
        if (display.replacementDiscount != null &&
            display.replacementDiscount! > 0)
          CompletionDetailTile(
            icon: Icons.discount_outlined,
            label: 'Replacement Discount',
            value: formatReturnCreditAdjustment(
              currency: display.currencyCode,
              amount: display.replacementDiscount!,
            ),
          ),
        if (display.replacementTax != null)
          CompletionDetailTile(
            icon: Icons.percent_outlined,
            label: 'Replacement Tax',
            value: formatReturnCreditAmount(
              currency: display.currencyCode,
              amount: display.replacementTax!,
            ),
          ),
        if (display.replacementItemValue != null)
          CompletionDetailTile(
            icon: Icons.shopping_bag_outlined,
            label: 'Replacement Total',
            value: formatReturnCreditAmount(
              currency: display.currencyCode,
              amount: display.replacementItemValue!,
            ),
          ),
        if (display.differenceAmount != null)
          CompletionDetailTile(
            icon: Icons.payments_outlined,
            label: _differenceLabel(display.differenceDirection),
            value: formatReturnCreditAmount(
              currency: display.currencyCode,
              amount: display.differenceAmount!.abs(),
            ),
            highlight: true,
          ),
        if (display.showPaidRefundedAmount &&
            (display.amountPaidByCustomer ?? 0) > 0)
          CompletionDetailTile(
            icon: Icons.south_west_rounded,
            label: 'Customer Paid',
            value: formatReturnCreditAmount(
              currency: display.currencyCode,
              amount: display.amountPaidByCustomer!,
            ),
          ),
        if (display.showPaidRefundedAmount &&
            (display.amountRefundedToCustomer ?? 0) > 0)
          CompletionDetailTile(
            icon: Icons.north_east_rounded,
            label: 'Customer Refunded',
            value: formatReturnCreditAmount(
              currency: display.currencyCode,
              amount: display.amountRefundedToCustomer!,
            ),
          ),
      ] else ...[
        CompletionDetailTile(
          icon: Icons.credit_card_outlined,
          label: 'Refund Method',
          value: display.methodLabel,
        ),
        if (display.returnSubtotal != null)
          CompletionDetailTile(
            icon: Icons.list_alt_outlined,
            label: 'Subtotal',
            value: formatReturnCreditAmount(
              currency: display.currencyCode,
              amount: display.returnSubtotal!,
            ),
          ),
        if (display.returnDiscount != null && display.returnDiscount! > 0)
          CompletionDetailTile(
            icon: Icons.discount_outlined,
            label: 'Discount',
            value: formatReturnCreditAdjustment(
              currency: display.currencyCode,
              amount: display.returnDiscount!,
            ),
          ),
        if (display.returnTax != null)
          CompletionDetailTile(
            icon: Icons.percent_outlined,
            label: 'Tax',
            value: formatReturnCreditAmount(
              currency: display.currencyCode,
              amount: display.returnTax!,
            ),
          ),
        CompletionDetailTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Total Refund Amount',
          value: formatReturnCreditAmount(
            currency: display.currencyCode,
            amount: display.returnTotal ?? display.totalAmount,
          ),
          highlight: true,
        ),
        if (display.showCardDetails) ...[
          if (display.cardBrand != null && display.cardBrand!.trim().isNotEmpty)
            CompletionDetailTile(
              icon: Icons.credit_score_outlined,
              label: 'Card Brand',
              value: display.cardBrand!.trim(),
            ),
          if (display.maskedCard != null &&
              display.maskedCard!.trim().isNotEmpty)
            CompletionDetailTile(
              icon: Icons.password_outlined,
              label: 'Card',
              value: display.maskedCard!.trim(),
            ),
          if (display.providerTransactionReference != null &&
              display.providerTransactionReference!.trim().isNotEmpty)
            CompletionDetailTile(
              icon: Icons.tag_outlined,
              label: 'Transaction Reference',
              value: display.providerTransactionReference!.trim(),
            ),
        ],
      ],
      CompletionDetailTile(
        icon: Icons.inventory_2_outlined,
        label: display.isExchange
            ? 'Total Exchanged Items'
            : 'Total Returned Items',
        value: '${display.itemCount}',
      ),
      CompletionDetailTile(
        icon: Icons.schedule_outlined,
        label: 'Completed Time',
        value: formatReturnReceiptDateTime(display.completedAt),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 560;
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final tile in [...left, ...right]) ...[
                  tile,
                  const SizedBox(height: TenantAdminSpacing.lg),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < left.length; i++) ...[
                      left[i],
                      if (i < left.length - 1)
                        const SizedBox(height: TenantAdminSpacing.lg),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.xl),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < right.length; i++) ...[
                      right[i],
                      if (i < right.length - 1)
                        const SizedBox(height: TenantAdminSpacing.lg),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _differenceLabel(String? direction) {
    switch (direction?.trim().toUpperCase()) {
      case 'CUSTOMER_PAYS':
        return 'Customer Pays';
      case 'CUSTOMER_RECEIVES':
        return 'Customer Receives';
      case 'EVEN':
      case 'EVEN_EXCHANGE':
      case 'NO_SETTLEMENT':
        return 'Even Exchange';
      default:
        return 'Difference';
    }
  }
}
