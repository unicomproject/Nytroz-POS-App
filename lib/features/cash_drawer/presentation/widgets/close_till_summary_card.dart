import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/cash_drawer_provider.dart';
import '../providers/close_till_provider.dart';
import 'cash_drawer_section_card.dart';

class CloseTillSummaryCard extends ConsumerWidget {
  const CloseTillSummaryCard({
    super.key,
    required this.expectedCash,
  });

  final double expectedCash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(closeTillFormProvider);
    final counted = formState.parsedCountedCash;
    final difference = formState.differenceFor(expectedCash);
    final closingStatus = formState.summaryClosingStatusLabel(expectedCash);
    final statusColors = closeTillClosingStatusColors(closingStatus);

    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Till Close Summary',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final useFourColumns =
                  constraints.maxWidth >= TenantAdminBreakpoints.tablet;
              final useTwoColumns =
                  !useFourColumns &&
                      constraints.maxWidth >= TenantAdminBreakpoints.mobile;

              final expectedItem = _SummaryColumn(
                label: 'Expected Cash',
                value: formatCashDrawerAmount(expectedCash),
              );
              final countedItem = _SummaryColumn(
                label: 'Counted Cash',
                value: counted == null
                    ? '-'
                    : formatCashDrawerAmount(counted),
              );
              final differenceItem = _SummaryColumn(
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
              );
              final statusItem = _SummaryColumn(
                label: 'Closing Status',
                child: _ClosingStatusChip(
                  label: closingStatus,
                  colors: statusColors,
                ),
              );

              final items = [
                expectedItem,
                countedItem,
                differenceItem,
                statusItem,
              ];

              if (useFourColumns) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < items.length; index += 1) ...[
                      if (index > 0)
                        const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(child: items[index]),
                    ],
                  ],
                );
              }

              if (useTwoColumns) {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: items[0]),
                        const SizedBox(width: TenantAdminSpacing.lg),
                        Expanded(child: items[1]),
                      ],
                    ),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < items.length; index += 1) ...[
                    if (index > 0) const SizedBox(height: TenantAdminSpacing.md),
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
    return Column(
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
        if (child != null)
          child!
        else
          Text(
            value ?? '-',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor ?? TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
          ),
      ],
    );
  }
}

class _ClosingStatusChip extends StatelessWidget {
  const _ClosingStatusChip({
    required this.label,
    required this.colors,
  });

  final String label;
  final CloseTillColorPair colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
