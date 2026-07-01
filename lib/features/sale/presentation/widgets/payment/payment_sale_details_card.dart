import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'payment_panel_card.dart';

class PaymentSaleDetailsCard extends StatelessWidget {
  const PaymentSaleDetailsCard({
    super.key,
    required this.saleType,
    required this.itemCount,
    required this.cashierName,
    required this.saleDate,
  });

  final String saleType;
  final int itemCount;
  final String cashierName;
  final String saleDate;

  @override
  Widget build(BuildContext context) {
    return PaymentPanelCard(
      title: 'Sale Details',
      icon: Icons.description_outlined,
      child: Column(
        children: [
          _DetailRow(label: 'Sale Type', value: saleType),
          const SizedBox(height: TenantAdminSpacing.sm),
          _DetailRow(label: 'Items in Cart', value: '$itemCount'),
          const SizedBox(height: TenantAdminSpacing.sm),
          _DetailRow(label: 'Date', value: saleDate),
          const SizedBox(height: TenantAdminSpacing.sm),
          _DetailRow(label: 'Cashier', value: cashierName),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}
