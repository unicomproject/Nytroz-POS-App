import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class RefundDetailsHeader extends StatelessWidget {
  const RefundDetailsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Refund Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'Select the refund method and confirm the refund.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TenantAdminColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
