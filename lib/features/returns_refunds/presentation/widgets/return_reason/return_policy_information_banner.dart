import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnPolicyInformationBanner extends StatelessWidget {
  const ReturnPolicyInformationBanner({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.primary.withValues(alpha: 0.06),
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
            size: 20,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
