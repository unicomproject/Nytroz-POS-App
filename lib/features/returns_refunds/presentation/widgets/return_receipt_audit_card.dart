import 'package:flutter/material.dart';

import '../../../cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_receipt.dart';

class ReturnReceiptAuditCard extends StatelessWidget {
  const ReturnReceiptAuditCard({
    super.key,
    required this.receipt,
  });

  final ReturnReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: TenantAdminColors.success,
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Text(
                'Audit & Confirmation',
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final useRow =
                  constraints.maxWidth >= TenantAdminBreakpoints.tablet;

              final items = [
                _AuditItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Cashier',
                  value: receipt.cashierName.isEmpty ? '-' : receipt.cashierName,
                ),
                _AuditItem(
                  icon: Icons.point_of_sale_outlined,
                  label: 'Till',
                  value: receipt.tillName.isEmpty ? '-' : receipt.tillName,
                ),
                _AuditItem(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Approval Status',
                  value: receipt.approvalStatus,
                  valueColor: TenantAdminColors.success,
                ),
                _AuditItem(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Customer Acknowledgement',
                  value: receipt.customerAcknowledgement,
                  valueColor: TenantAdminColors.success,
                ),
              ];

              if (useRow) {
                return Row(
                  children: [
                    for (var index = 0; index < items.length; index += 1) ...[
                      if (index > 0) const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(child: items[index]),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  for (var index = 0; index < items.length; index += 1) ...[
                    if (index > 0) const SizedBox(height: TenantAdminSpacing.lg),
                    items[index],
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AuditItem extends StatelessWidget {
  const _AuditItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: TenantAdminColors.primary, size: 20),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: TenantAdminColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: valueColor ?? TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
