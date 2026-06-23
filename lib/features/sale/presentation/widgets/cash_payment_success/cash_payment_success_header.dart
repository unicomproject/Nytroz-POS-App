import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CashPaymentSuccessHeader extends StatelessWidget {
  const CashPaymentSuccessHeader({
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
          tooltip: 'Back to New Sale',
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
                'Cash Payment',
                style: TenantAdminTextStyles.pageTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                'Payment completed successfully',
                style: TenantAdminTextStyles.muted(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
