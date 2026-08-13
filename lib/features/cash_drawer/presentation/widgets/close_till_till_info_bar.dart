import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/cash_drawer_summary.dart';
import '../providers/cash_drawer_provider.dart';
import 'cash_drawer_section_card.dart';

class CloseTillTillInfoBar extends StatelessWidget {
  const CloseTillTillInfoBar({
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
          final useFourColumns =
              constraints.maxWidth >= TenantAdminBreakpoints.tablet;
          final useTwoColumns = !useFourColumns &&
              constraints.maxWidth >= TenantAdminBreakpoints.mobile;

          final items = [
            _TillInfoItem(
              icon: Icons.point_of_sale_outlined,
              label: 'Till',
              value: summary.tillName,
            ),
            _TillInfoItem(
              icon: Icons.person_outline_rounded,
              label: 'Opened By',
              value: summary.openedBy,
            ),
            _TillInfoItem(
              icon: Icons.schedule_outlined,
              label: 'Opened Time',
              value: formatCashDrawerOpenedTime(summary.openedTime),
            ),
            _TillInfoItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Expected Cash',
              value: formatCashDrawerAmount(
                summary.currentExpectedCash,
                currencyCode: summary.currencyCode,
              ),
            ),
          ];

          if (useFourColumns) {
            return Row(
              children: [
                for (var index = 0; index < items.length; index += 1) ...[
                  if (index > 0) const SizedBox(width: TenantAdminSpacing.lg),
                  Expanded(child: items[index]),
                ],
              ],
            );
          }

          if (useTwoColumns) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: items[0]),
                    const SizedBox(width: TenantAdminSpacing.lg),
                    Expanded(child: items[1]),
                  ],
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                Row(
                  children: [
                    Expanded(child: items[2]),
                    const SizedBox(width: TenantAdminSpacing.lg),
                    Expanded(child: items[3]),
                  ],
                ),
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
            color: TenantAdminColors.expectedCashSurface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: Icon(
            icon,
            color: TenantAdminColors.posHomeAccentOrange,
            size: 22,
          ),
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
