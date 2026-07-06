import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnReasonValidationMessage extends StatelessWidget {
  const ReturnReasonValidationMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: TenantAdminColors.primary,
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Text(
            'A return reason is required to continue.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TenantAdminColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
