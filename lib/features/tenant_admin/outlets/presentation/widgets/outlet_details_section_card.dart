import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class OutletDetailsSectionCard extends StatelessWidget {
  const OutletDetailsSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(TenantAdminSpacing.xl),
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          child,
        ],
      ),
    );
  }
}
