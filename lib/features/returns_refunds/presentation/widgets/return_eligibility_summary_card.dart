import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/return_eligibility_provider.dart';

class ReturnEligibilitySummaryCard extends ConsumerWidget {
  const ReturnEligibilitySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(returnEligibilityProvider);
    final eligibility = state.eligibility;
    final currency = eligibility?.currency ?? 'LKR';
    final selectedItems = state.selectedItems;

    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Return Summary',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Text(
            'Selected Items',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          if (selectedItems.isEmpty)
            Text(
              'Select returnable items to preview the estimated return value.',
              style: TenantAdminTextStyles.muted(context),
            )
          else
            Column(
              children: [
                for (final item in selectedItems) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      Text(
                        formatReturnEligibilityAmount(
                          currency: currency,
                          amount: item.unitPrice *
                              (state.selectionFor(item.saleLineId)?.returnQty ??
                                  0),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.sm),
                ],
              ],
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.lg),
            child: Divider(color: TenantAdminColors.border),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Estimated Return Value',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                formatReturnEligibilityAmount(
                  currency: currency,
                  amount: state.estimatedReturnValue,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: TenantAdminColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _SummaryStatRow(
            label: 'Total Selected Items',
            value: '${state.selectedItemCount}',
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          _SummaryStatRow(
            label: 'Eligible Items',
            value: '${state.eligibleItemCount}',
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          _SummaryStatRow(
            label: 'Ineligible Items',
            value: '${state.ineligibleItemCount}',
          ),
        ],
      ),
    );
  }
}

class _SummaryStatRow extends StatelessWidget {
  const _SummaryStatRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TenantAdminTextStyles.muted(context),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}
