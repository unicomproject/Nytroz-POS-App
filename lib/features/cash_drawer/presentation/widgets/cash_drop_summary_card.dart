import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/cash_drawer_provider.dart';
import '../providers/cash_drop_provider.dart';
import 'cash_drawer_section_card.dart';

class CashDropSummaryCard extends ConsumerWidget {
  const CashDropSummaryCard({
    super.key,
    required this.currentExpectedCash,
  });

  final double currentExpectedCash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(cashDropFormProvider);
    final dropAmount = formState.parsedAmount ?? 0;
    final remaining = cashDropRemainingExpectedCash(
      currentExpectedCash: currentExpectedCash,
      form: formState,
    );

    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cash Drop Summary',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _SummaryRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Current Expected Cash',
            value: formatCashDrawerAmount(currentExpectedCash),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryRow(
            icon: Icons.remove_circle_outline_rounded,
            label: 'Cash Drop Amount',
            value: formState.hasValidAmount
                ? '- ${formatCashDrawerAmount(dropAmount)}'
                : '- ${formatLkrInputPrefix()} 0.00',
            valueColor: TenantAdminColors.info,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.lg),
            child: Divider(color: TenantAdminColors.border),
          ),
          _SummaryRow(
            icon: Icons.payments_outlined,
            label: 'Remaining Expected Cash',
            value: formatCashDrawerAmount(remaining),
            emphasize: true,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          const _CashDropInfoBanner(),
        ],
      ),
    );
  }
}

class _CashDropInfoBanner extends StatelessWidget {
  const _CashDropInfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.secondary,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: TenantAdminColors.info.withValues(alpha: .2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: TenantAdminColors.info,
            size: 20,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              'A cash movement slip will be printed after you confirm the cash drop.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
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
