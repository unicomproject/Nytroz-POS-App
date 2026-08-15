import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/cash_drawer_summary.dart';
import '../providers/cash_drawer_provider.dart';

class CashDrawerTillSummarySection extends StatelessWidget {
  const CashDrawerTillSummarySection({
    super.key,
    required this.summary,
    this.compact = false,
  });

  final CashDrawerSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'TILL SUMMARY',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
        ),
        SizedBox(
          height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.lg,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = compact
                ? 5
                : width >= TenantAdminBreakpoints.desktop
                    ? 5
                    : width >= TenantAdminBreakpoints.tablet
                        ? 3
                        : width >= TenantAdminBreakpoints.mobile
                            ? 2
                            : 1;
            final gap =
                compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md;
            final tileWidth = columns == 1
                ? width
                : ((width - gap * (columns - 1)) / columns).floorToDouble();

            final tiles = [
              _SummaryTile(
                label: 'Till',
                value: summary.tillName,
                icon: Icons.point_of_sale_rounded,
                iconColor: TenantAdminColors.posHomeAccentOrange,
                compact: compact,
              ),
              _SummaryTile(
                label: 'Status',
                value: summary.isOpen ? 'Open' : summary.status,
                icon: Icons.show_chart_rounded,
                iconColor: summary.isOpen
                    ? TenantAdminColors.success
                    : TenantAdminColors.mutedText,
                valueColor: summary.isOpen
                    ? TenantAdminColors.success
                    : TenantAdminColors.mutedText,
                compact: compact,
              ),
              _SummaryTile(
                label: 'Opening Cash',
                value: formatCashDrawerAmount(
                  summary.openingCash,
                  currencyCode: summary.currencyCode,
                ),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: TenantAdminColors.posHomeAccentOrange,
                compact: compact,
              ),
              _SummaryTile(
                label: 'Cash Sales',
                value: formatCashDrawerAmount(
                  summary.cashSales,
                  currencyCode: summary.currencyCode,
                ),
                icon: Icons.bar_chart_rounded,
                iconColor: TenantAdminColors.success,
                compact: compact,
              ),
              _SummaryTile(
                label: 'Current Expected Cash',
                value: formatCashDrawerAmount(
                  summary.currentExpectedCash,
                  currencyCode: summary.currencyCode,
                ),
                icon: Icons.account_balance_wallet_rounded,
                iconColor: TenantAdminColors.posHomeAccentOrange,
                emphasize: true,
                compact: compact,
              ),
            ];

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final tile in tiles)
                  SizedBox(
                    width: columns == 1 ? width : tileWidth,
                    child: tile,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
    this.emphasize = false,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;
  final bool emphasize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 52 : 88),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.lg,
          vertical: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: emphasize
              ? TenantAdminColors.expectedCashSurface
              : TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(
            color: emphasize
                ? TenantAdminColors.posHomeAccentOrange
                : TenantAdminColors.border,
            width: emphasize ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: compact ? 16 : 22),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: (compact
                            ? Theme.of(context).textTheme.labelSmall
                            : Theme.of(context).textTheme.labelMedium)
                        ?.copyWith(
                      color: TenantAdminColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(
                    height: compact ? 2 : TenantAdminSpacing.sm,
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (compact
                            ? Theme.of(context).textTheme.titleSmall
                            : Theme.of(context).textTheme.titleMedium)
                        ?.copyWith(
                      color: valueColor ??
                          (emphasize
                              ? TenantAdminColors.posHomeAccentOrange
                              : TenantAdminColors.bodyText),
                      fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
