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
  });

  final double currentExpectedCash;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(cashInFormProvider);
    final cashInAmount = formState.parsedAmount ?? 0;
    final newExpected = cashInNewExpectedCash(
      currentExpectedCash: currentExpectedCash,
      form: formState,
    );

    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cash In Summary',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _SummaryRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Current Expected Cash',
            value: formatCashDrawerAmount(
              currentExpectedCash,
              currencyCode: currencyCode,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryRow(
            icon: Icons.add_circle_outline_rounded,
            label: 'Cash In Amount',
            value: formState.hasValidAmount
                ? '+ ${formatCashDrawerAmount(cashInAmount, currencyCode: currencyCode)}'
                : '+ ${formatCashDrawerAmount(0, currencyCode: currencyCode)}',
            valueColor: TenantAdminColors.success,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.lg),
            child: Divider(color: TenantAdminColors.border),
          ),
          _SummaryRow(
            icon: Icons.payments_outlined,
            label: 'New Expected Cash',
            value: formatCashDrawerAmount(
              newExpected,
              currencyCode: currencyCode,
            ),
            emphasize: true,
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
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: emphasize
                ? TenantAdminColors.secondary
                : TenantAdminColors.background,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: emphasize
                ? TenantAdminColors.info
                : TenantAdminColors.mutedText,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: valueColor ?? TenantAdminColors.bodyText,
                      fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
