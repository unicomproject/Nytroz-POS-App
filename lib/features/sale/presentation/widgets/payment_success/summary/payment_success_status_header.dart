import 'package:flutter/material.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PaymentSuccessStatusHeader extends StatelessWidget {
  const PaymentSuccessStatusHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 64,
          color: TenantAdminColors.success,
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        const Text(
          'Sale Completed',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: TenantAdminColors.bodyText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'The transaction has been successfully processed.',
          style: TextStyle(
            fontSize: 16,
            color: TenantAdminColors.bodyText.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
