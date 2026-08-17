import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/cash_drawer_provider.dart';
import '../providers/cash_in_provider.dart';
import 'cash_drawer_section_card.dart';

class CashInSummaryCard extends ConsumerWidget {
  const CashInSummaryCard({
    super.key,
    required this.currentExpectedCash,
    required this.currencyCode,
    this.expand = false,
    this.compact = false,
    this.tight = false,
  });

  final double currentExpectedCash;
  final String currencyCode;
  final bool expand;
  final bool compact;
  final bool tight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(cashInFormProvider);
    final cashInAmount = formState.parsedAmount ?? 0;
    final newExpected = cashInNewExpectedCash(
      currentExpectedCash: currentExpectedCash,
      form: formState,
    );

    return CashDrawerSectionCard(
      expand: expand,
      padding: EdgeInsets.all(
        tight
            ? TenantAdminSpacing.sm
            : compact
                ? TenantAdminSpacing.lg
                : TenantAdminSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: tight ? 28 : 36,
                height: tight ? 28 : 36,
                decoration: BoxDecoration(
                  color: TenantAdminColors.expectedCashSurface,
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                ),
                child: Icon(
                  Icons.calculate_outlined,
                  color: TenantAdminColors.posHomeAccentOrange,
                  size: tight ? 17 : 21,
                ),
              ),
              SizedBox(
                width: tight ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
              ),
              Text(
                'Cash In Summary',
                style: TenantAdminTextStyles.sectionTitle(context).copyWith(
                  fontSize: tight ? 14 : null,
                ),
              ),
            ],
          ),
          SizedBox(
            height: tight
                ? TenantAdminSpacing.xs
                : compact
                    ? TenantAdminSpacing.md
                    : TenantAdminSpacing.lg,
          ),
          _SummaryRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Current Expected Cash',
            value: formatCashDrawerAmount(
              currentExpectedCash,
              currencyCode: currencyCode,
            ),
            compact: tight,
          ),
          SizedBox(
            height: tight
                ? TenantAdminSpacing.xs
                : compact
                    ? TenantAdminSpacing.sm
                    : TenantAdminSpacing.md,
          ),
          _SummaryRow(
            icon: Icons.add_circle_outline_rounded,
            label: 'Cash In Amount',
            value: formState.hasValidAmount
                ? '+ ${formatCashDrawerAmount(cashInAmount, currencyCode: currencyCode)}'
                : '+ ${formatCashDrawerAmount(0, currencyCode: currencyCode)}',
            valueColor: TenantAdminColors.success,
            compact: tight,
          ),
          if (expand) const Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: tight
                  ? TenantAdminSpacing.xs
                  : compact
                      ? TenantAdminSpacing.md
                      : TenantAdminSpacing.lg,
            ),
            child: const Divider(color: TenantAdminColors.border),
          ),
          _SummaryRow(
            icon: Icons.payments_outlined,
            label: 'New Expected Cash',
            value: formatCashDrawerAmount(
              newExpected,
              currencyCode: currencyCode,
            ),
            emphasize: true,
            highlighted: true,
            compact: tight,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
    this.highlighted = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;
  final bool highlighted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: compact ? 28 : 36,
          height: compact ? 28 : 36,
          decoration: BoxDecoration(
            color: emphasize
                ? TenantAdminColors.expectedCashSurface
                : TenantAdminColors.subtleBackground,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          ),
          child: Icon(
            icon,
            size: compact ? 16 : 20,
            color: emphasize
                ? TenantAdminColors.posHomeAccentOrange
                : TenantAdminColors.mutedText,
          ),
        ),
        SizedBox(
          width: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
        ),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: compact ? 11 : null,
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: compact ? 12 : null,
                  color: valueColor ??
                      (emphasize
                          ? TenantAdminColors.posHomeAccentOrange
                          : TenantAdminColors.bodyText),
                  fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
                ),
          ),
        ),
      ],
    );

    if (!highlighted) return row;
    return Container(
      padding: EdgeInsets.all(
        compact ? TenantAdminSpacing.sm : TenantAdminSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.expectedCashSurface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: row,
    );
  }
}
