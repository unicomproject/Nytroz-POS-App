import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_cash_drawer_till_visibility.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/cash_drawer_provider.dart';
import '../providers/close_till_provider.dart';
import 'cash_drawer_section_card.dart';

class CloseTillSummaryCard extends ConsumerWidget {
  const CloseTillSummaryCard({
    super.key,
    required this.expectedCash,
  });

  final double? expectedCash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(effectivePermissionSetProvider);
    final formState = ref.watch(closeTillFormProvider);
    final counted = formState.parsedCountedCash;

    final showSummary =
        PosCashDrawerTillVisibility.canShowClosingSummary(p);
    final showExpectedSummary =
        PosCashDrawerTillVisibility.canShowClosingExpectedCashSummary(p) &&
            PosCashDrawerTillVisibility.canShowClosingExpectedCash(p);
    final showCountedSummary =
        PosCashDrawerTillVisibility.canShowClosingCountedCashSummary(p);
    final showDifferenceSummary =
        PosCashDrawerTillVisibility.canShowClosingDifferenceSummary(p) &&
            PosCashDrawerTillVisibility.canShowClosingExpectedCash(p);
    final showStatusSummary =
        PosCashDrawerTillVisibility.canShowClosingStatusSummary(p) &&
            PosCashDrawerTillVisibility.canShowClosingExpectedCash(p);

    if (!showSummary &&
        !showExpectedSummary &&
        !showCountedSummary &&
        !showDifferenceSummary &&
        !showStatusSummary) {
      return const SizedBox.shrink();
    }

    final safeExpected = showExpectedSummary ? expectedCash : null;
    final difference = showDifferenceSummary
        ? formState.differenceFor(safeExpected)
        : null;
    final closingStatus = showStatusSummary
        ? formState.summaryClosingStatusLabel(safeExpected)
        : null;
    final statusColors = closingStatus == null
        ? null
        : closeTillClosingStatusColors(closingStatus);

    final items = <Widget>[
      if (showExpectedSummary)
        _SummaryColumn(
          label: 'Expected Cash',
          value: formatCashDrawerAmount(expectedCash),
        ),
      if (showCountedSummary)
        _SummaryColumn(
          label: 'Counted Cash',
          value: counted == null ? '-' : formatCashDrawerAmount(counted),
        ),
      if (showDifferenceSummary)
        _SummaryColumn(
          label: 'Difference',
          value: difference == null
              ? '-'
              : difference == 0
                  ? formatCashDrawerAmount(0)
                  : difference > 0
                      ? '+ ${formatCashDrawerAmount(difference)}'
                      : '- ${formatCashDrawerAmount(difference.abs())}',
          valueColor: difference == null
              ? TenantAdminColors.bodyText
              : difference == 0
                  ? TenantAdminColors.success
                  : difference > 0
                      ? TenantAdminColors.success
                      : TenantAdminColors.danger,
        ),
      if (showStatusSummary && closingStatus != null && statusColors != null)
        _SummaryColumn(
          label: 'Closing Status',
          child: _ClosingStatusChip(
            label: closingStatus,
            colors: statusColors,
          ),
        ),
    ];

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return CashDrawerSectionCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Till Close Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: TenantAdminColors.bodyText,
                  fontSize: 17,
                ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final useFourColumns =
                  constraints.maxWidth >= TenantAdminBreakpoints.tablet;
              final useTwoColumns = !useFourColumns &&
                  constraints.maxWidth >= TenantAdminBreakpoints.mobile;

              if (useFourColumns || items.length <= 2) {
                return Row(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: items[i]),
                    ],
                  ],
                );
              }
              if (useTwoColumns) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: (constraints.maxWidth - 8) / 2,
                        child: item,
                      ),
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    items[i],
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

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    this.value,
    this.valueColor,
    this.child,
  });

  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: value == null ? label : '$label $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          child ??
              Text(
                value ?? '-',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: valueColor ?? TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
              ),
        ],
      ),
    );
  }
}

class _ClosingStatusChip extends StatelessWidget {
  const _ClosingStatusChip({required this.label, required this.colors});

  final String label;
  final CloseTillColorPair colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
