import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'cash_drawer_section_card.dart';
import '../../domain/entities/cash_drawer_summary.dart';
import '../providers/cash_drawer_provider.dart';

class CashDrawerTillSummarySection extends StatelessWidget {
  const CashDrawerTillSummarySection({
    super.key,
    required this.summary,
  });

  final CashDrawerSummary summary;

  @override
  Widget build(BuildContext context) {
    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Till Summary',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= TenantAdminBreakpoints.tablet
                  ? 4
                  : width >= TenantAdminBreakpoints.mobile
                      ? 2
                      : 1;
              final tileWidth = columns == 1
                  ? width
                  : (width - TenantAdminSpacing.md * (columns - 1)) / columns;

              final tiles = [
                _SummaryTile(label: 'Till', value: summary.tillName),
                _SummaryTile(
                  label: 'Status',
                  value: summary.status,
                  valueColor: summary.isOpen
                      ? TenantAdminColors.success
                      : TenantAdminColors.mutedText,
                ),
                _SummaryTile(label: 'Opened By', value: summary.openedBy),
                _SummaryTile(
                  label: 'Opened Time',
                  value: formatCashDrawerOpenedTime(summary.openedTime),
                ),
                _SummaryTile(
                  label: 'Opening Cash',
                  value: formatCashDrawerAmount(summary.openingCash),
                ),
                _SummaryTile(
                  label: 'Cash Sales',
                  value: formatCashDrawerAmount(summary.cashSales),
                ),
                _SummaryTile(
                  label: 'Cash Refunds',
                  value: formatCashDrawerAmount(summary.cashRefunds),
                ),
                _SummaryTile(
                  label: 'Cash Drops',
                  value: formatCashDrawerAmount(summary.cashDrops),
                ),
                _SummaryTile(
                  label: 'Current Expected Cash',
                  value: formatCashDrawerAmount(summary.currentExpectedCash),
                  emphasize: true,
                ),
              ];

              return Wrap(
                spacing: TenantAdminSpacing.md,
                runSpacing: TenantAdminSpacing.md,
                children: [
                  for (final tile in tiles)
                    SizedBox(
                      width: tileWidth,
                      child: tile,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: emphasize ? TenantAdminColors.secondary : TenantAdminColors.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: emphasize ? TenantAdminColors.info.withValues(alpha: .25) : TenantAdminColors.border,
        ),
      ),
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
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor ?? TenantAdminColors.bodyText,
                  fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
