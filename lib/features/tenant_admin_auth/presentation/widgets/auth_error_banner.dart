import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border:
            Border.all(color: TenantAdminColors.danger.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: TenantAdminColors.danger),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
