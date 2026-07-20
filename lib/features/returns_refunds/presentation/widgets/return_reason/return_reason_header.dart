import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnReasonHeader extends StatelessWidget {
  const ReturnReasonHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Reason',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'Choose the reason for the return or exchange and capture notes if needed.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TenantAdminColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
