import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_sale_eligibility.dart';
import 'eligibility_check_item.dart';

class EligibilityChecklistCard extends StatelessWidget {
  const EligibilityChecklistCard({
    super.key,
    required this.checks,
  });

  final List<ReturnPolicyCheck> checks;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Eligibility Checklist',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (checks.isEmpty)
            Text(
              'No eligibility checks were returned for the selected items.',
              style: TenantAdminTextStyles.muted(context),
            )
          else
            for (var index = 0; index < checks.length; index += 1) ...[
              if (index > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.md),
                  child: Divider(color: TenantAdminColors.border, height: 1),
                ),
              EligibilityCheckItem(check: checks[index]),
            ],
        ],
      ),
    );
  }
}
