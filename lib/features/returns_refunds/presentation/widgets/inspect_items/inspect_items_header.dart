import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class InspectItemsHeader extends StatelessWidget {
  const InspectItemsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inspect Items',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'Inspect the condition of each selected item and add notes or photos if needed.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TenantAdminColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
