import 'package:flutter/material.dart';

import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_cash_payment_success_provider.dart';
import '../payment/payment_panel_card.dart';

class ReceiptPreviewSummaryCard extends StatelessWidget {
  const ReceiptPreviewSummaryCard({
    super.key,
    required this.successData,
  });

  final PosCashPaymentSuccessData successData;

  @override
  Widget build(BuildContext context) {
    return PaymentPanelCard(
      title: 'Receipt Preview',
      icon: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This is a summary of the receipt that will be sent.',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          DecoratedBox(
            decoration: BoxDecoration(
              color: TenantAdminColors.background,
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: TenantAdminColors.secondary,
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                      border: Border.all(color: TenantAdminColors.border),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: TenantAdminColors.info,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.lg),
                  Expanded(
                    child: Column(
                      children: [
                        _PreviewRow(
                          label: 'Receipt No.',
                          value: successData.receiptNumber,
                        ),
                        const SizedBox(height: TenantAdminSpacing.sm),
                        _PreviewRow(
                          label: 'Total Amount',
                          value: formatLkr(successData.total),
                        ),
                        const SizedBox(height: TenantAdminSpacing.sm),
                        const _PreviewRow(
                          label: 'Payment Method',
                          value: 'Cash',
                        ),
                        const SizedBox(height: TenantAdminSpacing.sm),
                        _PreviewRow(
                          label: 'Date & Time',
                          value: formatReceiptDateTime(successData.completedAt),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: TenantAdminSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Items Purchased',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: TenantAdminColors.bodyText,
                      ),
                ),
              ),
              Text(
                '${successData.itemCount} Items',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: TenantAdminColors.bodyText,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TenantAdminTextStyles.muted(context),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}
