import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

class TenantAdminFormSection extends StatelessWidget {
  const TenantAdminFormSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TenantAdminTextStyles.sectionTitle(context)),
                    if (subtitle != null) ...[
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(subtitle!,
                          style: TenantAdminTextStyles.muted(context)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          ..._withSpacing(children),
        ],
      ),
    );
  }
}

List<Widget> _withSpacing(List<Widget> children) {
  final spaced = <Widget>[];

  for (final child in children) {
    if (spaced.isNotEmpty) {
      spaced.add(const SizedBox(height: TenantAdminSpacing.lg));
    }

    spaced.add(child);
  }

  return spaced;
}
