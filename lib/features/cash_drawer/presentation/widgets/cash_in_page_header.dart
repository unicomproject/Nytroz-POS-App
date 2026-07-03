import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CashInPageHeader extends StatelessWidget {
  const CashInPageHeader({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onBack,
          tooltip: 'Back to Cash Drawer',
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: TenantAdminColors.surface,
            side: const BorderSide(color: TenantAdminColors.border),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cash In',
                style: TenantAdminTextStyles.pageTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                'Add extra cash or float to the current till drawer.',
                style: TenantAdminTextStyles.muted(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
