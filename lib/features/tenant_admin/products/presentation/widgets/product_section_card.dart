import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class ProductSectionCard extends StatelessWidget {
  const ProductSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08071A33),
            blurRadius: 24,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x04071A33),
            blurRadius: 6,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TenantAdminTextStyles.sectionTitle(context),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(
                        subtitle!,
                        style: TenantAdminTextStyles.muted(context)
                            .copyWith(fontSize: 12),
                      ),
                    ],
                  ],
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
