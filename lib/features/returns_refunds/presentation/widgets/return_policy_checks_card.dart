import 'package:flutter/material.dart';

import '../../../cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_sale_eligibility.dart';

class ReturnPolicyChecksCard extends StatelessWidget {
  const ReturnPolicyChecksCard({
    super.key,
    required this.checks,
  });

  final List<ReturnPolicyCheck> checks;

  @override
  Widget build(BuildContext context) {
    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Return Policy Checks',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          for (var index = 0; index < checks.length; index += 1) ...[
            if (index > 0) const SizedBox(height: TenantAdminSpacing.md),
            _PolicyCheckRow(check: checks[index]),
          ],
        ],
      ),
    );
  }
}

class _PolicyCheckRow extends StatelessWidget {
  const _PolicyCheckRow({required this.check});

  final ReturnPolicyCheck check;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        check.passed ? TenantAdminColors.success : TenantAdminColors.danger;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          check.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                check.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: TenantAdminColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                check.value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
