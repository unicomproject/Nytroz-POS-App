import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CashInPageHeader extends StatelessWidget {
  const CashInPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cash In', style: TenantAdminTextStyles.pageTitle(context)),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'Add extra cash or float to the current till drawer.',
          style: TenantAdminTextStyles.muted(context),
        ),
      ],
    );
  }
}
