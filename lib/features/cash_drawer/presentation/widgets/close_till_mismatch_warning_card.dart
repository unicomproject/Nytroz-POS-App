import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CloseTillMismatchWarningCard extends StatelessWidget {
  const CloseTillMismatchWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.danger),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: TenantAdminColors.danger,
            size: 24,
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mismatch review required',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: TenantAdminColors.danger,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  'There is a cash difference. Manager review and approval are required before closing the till.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TenantAdminColors.danger,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
