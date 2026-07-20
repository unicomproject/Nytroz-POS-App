import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CompletionDetailTile extends StatelessWidget {
  const CompletionDetailTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: TenantAdminColors.primary),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: TenantAdminColors.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '-' : value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: highlight
                          ? TenantAdminColors.primary
                          : TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
