import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PrintReceiptHeader extends StatelessWidget {
  const PrintReceiptHeader({
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
          tooltip: 'Back to payment success',
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
                'Print Receipt',
                style: TenantAdminTextStyles.pageTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                'Preview and print the sale receipt',
                style: TenantAdminTextStyles.muted(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
