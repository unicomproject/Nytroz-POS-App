import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PaymentPanelCard extends StatelessWidget {
  const PaymentPanelCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: TenantAdminColors.info, size: 22),
                const SizedBox(width: TenantAdminSpacing.sm),
                Text(title, style: TenantAdminTextStyles.sectionTitle(context)),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
