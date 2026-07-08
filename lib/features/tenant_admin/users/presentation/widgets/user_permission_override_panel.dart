import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/entities/tenant_user.dart';

class UserPermissionOverridePanel extends StatelessWidget {
  const UserPermissionOverridePanel({
    super.key,
    required this.groups,
    required this.selectedPermissionIds,
    required this.onChanged,
    required this.onReset,
  });

  final List<PermissionGroup> groups;
  final Set<String> selectedPermissionIds;
  final ValueChanged<Set<String>> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
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
                  'Permission Overrides',
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
              ),
              TenantAdminSecondaryButton(
                label: 'Reset to Role Defaults',
                icon: Icons.restart_alt,
                onPressed: onReset,
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'Select individual permissions to grant in addition to the role\'s '
            'defaults for this user.',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (groups.isEmpty)
            Text(
              'No permissions are available to override.',
              style: TenantAdminTextStyles.muted(context),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: groups.length,
                separatorBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: TenantAdminSpacing.md,
                  ),
                  child: Divider(height: 1, color: TenantAdminColors.border),
                ),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _PermissionGroupTile(
                    group: group,
                    selectedPermissionIds: selectedPermissionIds,
                    onChanged: onChanged,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PermissionGroupTile extends StatelessWidget {
  const _PermissionGroupTile({
    required this.group,
    required this.selectedPermissionIds,
    required this.onChanged,
  });

  final PermissionGroup group;
  final Set<String> selectedPermissionIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.groupName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        for (final permission in group.permissions)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: selectedPermissionIds.contains(permission.id),
            title: Text(
              permission.actionType.isNotEmpty
                  ? permission.actionType
                  : permission.code,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: permission.description == null
                ? null
                : Text(
                    permission.description!,
                    style: TenantAdminTextStyles.muted(context),
                  ),
            onChanged: (checked) {
              final next = {...selectedPermissionIds};
              if (checked == true) {
                next.add(permission.id);
              } else {
                next.remove(permission.id);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}
