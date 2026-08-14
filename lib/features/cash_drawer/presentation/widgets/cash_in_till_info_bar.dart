import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/cash_drawer_summary.dart';
import '../providers/cash_drawer_provider.dart';
import 'cash_drawer_section_card.dart';

class CashInTillInfoBar extends StatelessWidget {
  const CashInTillInfoBar({
    super.key,
    required this.summary,
  });

  final CashDrawerSummary summary;

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
            _TillInfoItem(
              icon: Icons.point_of_sale_outlined,
              label: 'Till',
              value: summary.tillName,
            ),
            _TillInfoItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Current Expected Cash',
              value: formatCashDrawerAmount(
                summary.currentExpectedCash,
                currencyCode: summary.currencyCode,
              ),
            ),
            _TillInfoItem(
              icon: Icons.savings_outlined,
              label: 'Opening Cash',
              value: formatCashDrawerAmount(
                summary.openingCash,
                currencyCode: summary.currencyCode,
              ),
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

class _TillInfoItem extends StatelessWidget {
  const _TillInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
                      color: TenantAdminColors.bodyText,
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
