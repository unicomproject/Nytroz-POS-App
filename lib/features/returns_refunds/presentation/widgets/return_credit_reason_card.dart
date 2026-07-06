import 'package:flutter/material.dart';

import '../../../cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnCreditReasonCard extends StatelessWidget {
  const ReturnCreditReasonCard({
    super.key,
    required this.reasonLabel,
  });

  final String reasonLabel;

  @override
  Widget build(BuildContext context) {
    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Return Reason',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            reasonLabel.isEmpty ? '-' : reasonLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: TenantAdminColors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
