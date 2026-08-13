import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

/// Page title + subtitle inside the main white Cash Drawer content card.
/// No back arrow on the main Cash Drawer screen.
class CashDrawerPageHeader extends StatelessWidget {
  const CashDrawerPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash Drawer',
          style: TenantAdminTextStyles.pageTitle(context),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'Monitor the till cash position and perform drawer actions.',
          style: TenantAdminTextStyles.muted(context),
        ),
      ],
    );
  }
}
