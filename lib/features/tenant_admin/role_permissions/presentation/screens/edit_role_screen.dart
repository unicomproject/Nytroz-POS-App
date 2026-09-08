import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/edit_role_providers.dart';
import '../providers/role_permissions_providers.dart';
import '../widgets/role_assignment_editor.dart';

class EditRoleScreen extends ConsumerWidget {
  const EditRoleScreen({
    super.key,
    required this.roleId,
  });

  final String roleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editRoleControllerProvider(roleId));
    final access = ref.watch(tenantAdminAccessCheckerProvider).valueOrNull;
    final canUpdateDetails = access?.canAny([
          TenantAdminPermissionCodes.tenantRolesUpdate,
          TenantAdminPermissionCodes.tenantRolesManage,
        ]) ??
        false;
    final canUpdatePermissions = access?.canAny([
          TenantAdminPermissionCodes.tenantRolesPermissionsUpdate,
          TenantAdminPermissionCodes.tenantRolesManage,
        ]) ??
        false;
    final canUpdateAssignments = access?.canAny([
          TenantAdminPermissionCodes.tenantRolesUsersAssign,
          TenantAdminPermissionCodes.tenantRolesOutletsAssign,
          TenantAdminPermissionCodes.tenantRolesManage,
        ]) ??
        false;

    if (!state.isInitialized) {
      return const TenantAdminPageScaffold(
        title: 'Edit Role',
        child: TenantAdminLoadingSkeleton(rowCount: 6),
      );
    }

    return DefaultTabController(
      length: 3,
      child: TenantAdminPageScaffold(
        title: 'Edit Role',
        subtitle: 'Update role details, permissions, and user assignments.',
        actions: [
          TenantAdminSecondaryButton(
            label: 'Cancel',
            onPressed: state.isSaving ? null : () => context.pop(),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          TenantAdminPrimaryButton(
            label: 'Save Changes',
            loading: state.isSaving,
            onPressed: state.isSaving
                ? null
                : () async {
                    final success = await ref
                        .read(editRoleControllerProvider(roleId).notifier)
                        .save(
                          roleId,
                          canUpdateDetails: canUpdateDetails,
                          canUpdatePermissions: canUpdatePermissions,
                          canUpdateAssignments: canUpdateAssignments,
                        );
                    if (success && context.mounted) {
                      context.pop();
                    }
                  },
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.error != null) ...[
              Container(
                padding: const EdgeInsets.all(TenantAdminSpacing.md),
                decoration: BoxDecoration(
                  color: TenantAdminColors.dangerSurface,
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  border: Border.all(color: TenantAdminColors.dangerBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: TenantAdminColors.danger, size: 20),
                    const SizedBox(width: TenantAdminSpacing.sm),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(
                            color: TenantAdminColors.danger, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xl),
            ],
            const TabBar(
              labelColor: TenantAdminColors.posHomeAccentOrange,
              unselectedLabelColor: TenantAdminColors.mutedText,
              indicatorColor: TenantAdminColors.posHomeAccentOrange,
              tabs: [
                Tab(text: 'General Details'),
                Tab(text: 'Permissions'),
                Tab(text: 'Assignments'),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.xl),
            Expanded(
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    child: _GeneralDetailsSection(
                      roleId: roleId,
                      canEdit: canUpdateDetails,
                    ),
                  ),
                  SingleChildScrollView(
                    child: _PermissionsSection(
                      roleId: roleId,
                      canEdit: canUpdatePermissions,
                    ),
                  ),
                  SingleChildScrollView(
                      child: _AssignmentsSection(roleId: roleId)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionsSection extends ConsumerWidget {
  const _PermissionsSection({required this.roleId, required this.canEdit});

  final String roleId;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(rolePermissionsDataProvider(roleId));
    final state = ref.watch(editRoleControllerProvider(roleId));
    return data.when(
      loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
      error: (error, stackTrace) => const TenantAdminErrorState(
        title: 'Unable to load permissions',
        message: 'Please try again.',
      ),
      data: (value) => Column(
        children: [
          for (final module in value.catalog.modules)
            Card(
              child: ExpansionTile(
                title: Text(module.name),
                children: [
                  for (final feature in module.features)
                    for (final permission in feature.permissions)
                      CheckboxListTile(
                        value: state.selectedPermissionCodes
                            .contains(permission.code),
                        onChanged: canEdit && permission.assignable
                            ? (_) => ref
                                .read(
                                    editRoleControllerProvider(roleId).notifier)
                                .togglePermission(permission.code)
                            : null,
                        title: Text(permission.name),
                        subtitle: Text(permission.code),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AssignmentsSection extends ConsumerWidget {
  const _AssignmentsSection({required this.roleId});

  final String roleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(roleAssignmentOptionsProvider);
    final state = ref.watch(editRoleControllerProvider(roleId));
    return options.when(
      loading: () => const TenantAdminLoadingSkeleton(rowCount: 5),
      error: (error, stackTrace) => const TenantAdminErrorState(
        title: 'Unable to load assignment options',
        message: 'Please try again.',
      ),
      data: (value) => RoleAssignmentEditor(
        options: value,
        assignments: state.assignments,
        onChanged: (assignments) => ref
            .read(editRoleControllerProvider(roleId).notifier)
            .updateAssignments(assignments),
      ),
    );
  }
}

class _GeneralDetailsSection extends ConsumerStatefulWidget {
  const _GeneralDetailsSection({required this.roleId, required this.canEdit});

  final String roleId;
  final bool canEdit;

  @override
  ConsumerState<_GeneralDetailsSection> createState() =>
      _GeneralDetailsSectionState();
}

class _GeneralDetailsSectionState
    extends ConsumerState<_GeneralDetailsSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(editRoleControllerProvider(widget.roleId));
    _nameController = TextEditingController(text: state.roleName);
    _descController = TextEditingController(text: state.description);
    _codeController = TextEditingController(text: state.roleCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onChanged() {
    ref
        .read(editRoleControllerProvider(widget.roleId).notifier)
        .updateGeneralDetails(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          code: _codeController.text.trim(),
        );
  }

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
          const Text(
            'General Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          TextFormField(
            controller: _nameController,
            readOnly: !widget.canEdit,
            decoration: const InputDecoration(
              labelText: 'Role Name *',
              hintText: 'e.g., Store Manager',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _onChanged(),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          TextFormField(
            controller: _codeController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Role Code',
              helperText: 'Role code is immutable after creation.',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _onChanged(),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          TextFormField(
            controller: _descController,
            readOnly: !widget.canEdit,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe what users with this role can do...',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _onChanged(),
          ),
        ],
      ),
    );
  }
}
