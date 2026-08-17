import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/cash_drawer_summary.dart';
import '../providers/cash_drawer_provider.dart';
import 'cash_drawer_section_card.dart';

class CashDropTillInfoBar extends StatelessWidget {
  const CashDropTillInfoBar({
    super.key,
    required this.summary,
    this.compact = false,
  });

  final CashDrawerSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final availableCash = summary.currentExpectedCash;

    return CashDrawerSectionCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? TenantAdminSpacing.md : TenantAdminSpacing.lg,
        vertical: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useRow =
              constraints.maxWidth >= TenantAdminBreakpoints.tablet;

          final items = [
            _TillInfoItem(
              icon: Icons.point_of_sale_outlined,
              label: 'Till',
              value: summary.tillName,
              compact: compact,
            ),
            _TillInfoItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Current Expected Cash',
              value: formatCashDrawerAmount(
                summary.currentExpectedCash,
                currencyCode: summary.currencyCode,
              ),
              emphasize: true,
              compact: compact,
            ),
            _TillInfoItem(
              icon: Icons.savings_outlined,
              label: 'Available Cash in Drawer',
              value: formatCashDrawerAmount(
                availableCash,
                currencyCode: summary.currencyCode,
              ),
              emphasize: true,
              compact: compact,
            ),
          ];

          if (useRow) {
            return Row(
              children: [
                for (var index = 0; index < items.length; index += 1) ...[
                  if (index > 0) ...[
                    const SizedBox(width: TenantAdminSpacing.md),
                    const SizedBox(
                      height: 48,
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: TenantAdminColors.border,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                  ],
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
    this.emphasize = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 32 : 40,
          height: compact ? 32 : 40,
          decoration: BoxDecoration(
            color: TenantAdminColors.expectedCashSurface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: Icon(
            icon,
            color: TenantAdminColors.posHomeAccentOrange,
            size: compact ? 18 : 22,
          ),
        ),
        SizedBox(
          width: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
        ),
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
              SizedBox(height: compact ? 2 : TenantAdminSpacing.xs),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: compact ? 13 : null,
                      color: emphasize
                          ? TenantAdminColors.posHomeAccentOrange
                          : TenantAdminColors.bodyText,
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
