import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import 'user_status_badge.dart';

class UserStatusPreview extends StatelessWidget {
  const UserStatusPreview({
    super.key,
    required this.status,
    required this.helperText,
  });

  final String status;
  final String helperText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.secondary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Preview',
                style: TenantAdminTextStyles.muted(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(helperText, style: TenantAdminTextStyles.muted(context)),
            ],
          ),
          const Spacer(),
          UserStatusBadge(status: status),
        ],
      ),
    );
  }
}
