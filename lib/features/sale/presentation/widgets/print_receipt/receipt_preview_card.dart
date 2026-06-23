import 'package:flutter/material.dart';

import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_cash_payment_success_provider.dart';
import '../payment/payment_panel_card.dart';

class ReceiptBusinessDetails {
  const ReceiptBusinessDetails({
    required this.businessName,
    required this.addressLines,
    required this.phone,
  });

  final String businessName;
  final List<String> addressLines;
  final String phone;

  static const demo = ReceiptBusinessDetails(
    businessName: 'SCS-TIX',
    addressLines: [
      'No. 12, Galle Road',
      'Colombo 03, Sri Lanka',
    ],
    phone: '+94 11 234 5678',
  );
}

class ReceiptPreviewCard extends StatelessWidget {
  const ReceiptPreviewCard({
    super.key,
    required this.successData,
    required this.cashierName,
    this.businessDetails = ReceiptBusinessDetails.demo,
  });

  final PosCashPaymentSuccessData successData;
  final String cashierName;
  final ReceiptBusinessDetails businessDetails;

  @override
  Widget build(BuildContext context) {
    final discountPercent = _percentOf(successData.discount, successData.subtotal);
    final taxPercent = _percentOf(successData.tax, successData.subtotal);

    return PaymentPanelCard(
      title: 'RECEIPT PREVIEW',
      icon: Icons.receipt_long_outlined,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: TenantAdminColors.background,
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    businessDetails.businessName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: TenantAdminColors.bodyText,
                        ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  for (final line in businessDetails.addressLines) ...[
                    Text(
                      line,
                      textAlign: TextAlign.center,
                      style: TenantAdminTextStyles.muted(context),
                    ),
                  ],
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(
                    'Tel: ${businessDetails.phone}',
                    textAlign: TextAlign.center,
                    style: TenantAdminTextStyles.muted(context),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _DashedDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _MetaLine(
                    label: 'Receipt No.',
                    value: successData.receiptNumber,
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  _MetaLine(
                    label: 'Date & Time',
                    value: formatReceiptDateTime(successData.completedAt),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  _MetaLine(label: 'Cashier', value: cashierName),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _DashedDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _ItemsHeaderRow(),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  for (final item in successData.items) ...[
                    _ItemRow(item: item),
                    const SizedBox(height: TenantAdminSpacing.sm),
                  ],
                  const SizedBox(height: TenantAdminSpacing.sm),
                  const _DashedDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _TotalLine(
                    label: 'Subtotal (${successData.itemCount})',
                    value: formatLkr(successData.subtotal),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  _TotalLine(
                    label: 'Discount ($discountPercent%)',
                    value: '- ${formatLkr(successData.discount)}',
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  _TotalLine(
                    label: 'Tax ($taxPercent%)',
                    value: formatLkr(successData.tax),
                  ),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  _TotalLine(
                    label: 'Total',
                    value: formatLkr(successData.total),
                    emphasized: true,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _DashedDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _TotalLine(label: 'Payment Method', value: 'Cash'),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  _TotalLine(
                    label: 'Cash Received',
                    value: formatLkr(successData.cashReceived),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  _TotalLine(
                    label: 'Change Due',
                    value: formatLkr(successData.changeDue),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _DashedDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  Text(
                    'Thank you for your purchase!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(
                    'Please come again.',
                    textAlign: TextAlign.center,
                    style: TenantAdminTextStyles.muted(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _percentOf(int amount, int base) {
    if (base <= 0 || amount <= 0) {
      return 0;
    }

    return ((amount * 100) / base).round();
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dashCount, (index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index == dashCount - 1 ? 0 : dashSpace,
              ),
              child: Container(
                width: dashWidth,
                height: 1,
                color: TenantAdminColors.border,
              ),
            );
          }),
        );
      },
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
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
          flex: 2,
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

class _ItemsHeaderRow extends StatelessWidget {
  const _ItemsHeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: TenantAdminColors.bodyText,
        );

    return Row(
      children: [
        Expanded(flex: 5, child: Text('Item', style: style)),
        Expanded(child: Text('Qty', style: style, textAlign: TextAlign.center)),
        Expanded(
          flex: 2,
          child: Text('Price (LKR)', style: style, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final PosCashPaymentSuccessLineItem item;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: style),
              if (item.variantSummary != null &&
                  item.variantSummary!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.variantSummary!,
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Text(
            '${item.quantity}',
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            _formatReceiptAmount(item.lineTotal),
            textAlign: TextAlign.end,
            style: style,
          ),
        ),
      ],
    );
  }

  String _formatReceiptAmount(int value) {
    return formatLkr(value).replaceFirst('LKR ', '');
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            )
        : Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
