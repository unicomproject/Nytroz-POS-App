import 'package:flutter/material.dart';

import '../../../cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_sale_eligibility.dart';
import '../providers/return_search_provider.dart';

class ReturnSaleContextBar extends StatelessWidget {
  const ReturnSaleContextBar({
    super.key,
    required this.eligibility,
  });

  final ReturnSaleEligibility eligibility;

  @override
  Widget build(BuildContext context) {
    return CashDrawerSectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.xl,
        vertical: TenantAdminSpacing.lg,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useRow = constraints.maxWidth >= TenantAdminBreakpoints.mobile;

          final items = [
            _ContextItem(
              icon: Icons.receipt_long_outlined,
              label: 'Original Sale',
              value: eligibility.invoiceNo,
              valueColor: TenantAdminColors.primary,
            ),
            _ContextItem(
              icon: Icons.person_outline_rounded,
              label: 'Customer',
              value: eligibility.customerName.isEmpty
                  ? 'Walk-in customer'
                  : eligibility.customerName,
            ),
            _ContextItem(
              icon: Icons.schedule_outlined,
              label: 'Sale Date & Time',
              value: formatReturnSaleDateTime(eligibility.saleDate),
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
                if (index > 0) const SizedBox(height: TenantAdminSpacing.md),
                items[index],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ContextItem extends StatelessWidget {
  const _ContextItem({
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
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: TenantAdminColors.secondary,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: Icon(icon, color: TenantAdminColors.info, size: 22),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
