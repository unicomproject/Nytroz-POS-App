import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class EligibilityPolicyNoteCard extends StatelessWidget {
  const EligibilityPolicyNoteCard({
    super.key,
    required this.note,
  });

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: TenantAdminColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: TenantAdminColors.primary,
            size: 18,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Policy Note',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: TenantAdminColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
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
