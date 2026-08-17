import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CashDropPageHeader extends StatelessWidget {
  const CashDropPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cash Drop', style: TenantAdminTextStyles.pageTitle(context)),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'Record a safe drop from the drawer and reduce the till cash balance.',
          style: TenantAdminTextStyles.muted(context),
        ),
      ],
    );
  }
}
