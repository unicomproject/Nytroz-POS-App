import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_user.dart';

class UserAccessSection extends StatelessWidget {
  const UserAccessSection({
    super.key,
    required this.outlets,
    required this.selectedOutletIds,
    required this.onOutletsChanged,
    required this.enabled,
    this.errorText,
  });

  final List<UserOutletOption> outlets;
  final Set<String> selectedOutletIds;
  final ValueChanged<Set<String>> onOutletsChanged;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: TenantAdminColors.secondary,
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              ),
              child: const Icon(
                Icons.store_outlined,
                size: 18,
                color: TenantAdminColors.primary,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Outlets',
                    style: TenantAdminTextStyles.sectionTitle(context),
                  ),
                  Text(
                    'Leave empty to grant access to all outlets.',
                    style: TenantAdminTextStyles.muted(context),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: errorText != null
                  ? TenantAdminColors.danger
                  : TenantAdminColors.border,
            ),
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: outlets.isEmpty
              ? Text(
                  'No outlets available for this tenant.',
                  style: TenantAdminTextStyles.muted(context),
                )
              : Wrap(
                  spacing: TenantAdminSpacing.sm,
                  runSpacing: TenantAdminSpacing.sm,
                  children: [
                    for (final outlet in outlets)
                      FilterChip(
                        label: Text(outlet.name),
                        selected: selectedOutletIds.contains(outlet.id),
                        onSelected: enabled
                            ? (selected) {
                                final next = {...selectedOutletIds};
                                if (selected) {
                                  next.add(outlet.id);
                                } else {
                                  next.remove(outlet.id);
                                }
                                onOutletsChanged(next);
                              }
                            : null,
                        selectedColor:
                            TenantAdminColors.primary.withValues(alpha: 0.14),
                        checkmarkColor: TenantAdminColors.primary,
                      ),
                  ],
                ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            errorText!,
            style: const TextStyle(
              color: TenantAdminColors.danger,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class UserToggleRow extends StatelessWidget {
  const UserToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(subtitle, style: TenantAdminTextStyles.muted(context)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: TenantAdminColors.primary,
          ),
        ],
      ),
    );
  }
}
