import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/permission_catalog.dart';
import '../providers/role_permissions_providers.dart';
import '../utils/permission_catalog_filters.dart';

class RolePermissionsScreen extends ConsumerWidget {
  const RolePermissionsScreen({
    super.key,
    this.initialRoleId,
  });

  final String? initialRoleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canView = ref.watch(rolePermissionsCanViewProvider);
    if (!canView) {
      return const TenantAdminPageScaffold(
        title: 'Roles & Permissions',
        subtitle:
            'Manage role permission assignments from the backend catalog.',
        child: TenantAdminEmptyState(
          title: 'No access',
          message:
              'You need roles.permissions.view to manage role permissions.',
        ),
      );
    }

    final availableRoles = ref.watch(rolePermissionsAvailableRolesProvider);
    final selectedRoleId = ref.watch(rolePermissionsSelectedRoleIdProvider) ??
        initialRoleId ??
        (availableRoles.isNotEmpty ? availableRoles.first.id : null);

    if (selectedRoleId == null || selectedRoleId.isEmpty) {
      return const TenantAdminPageScaffold(
        title: 'Roles & Permissions',
        subtitle:
            'Manage role permission assignments from the backend catalog.',
        child: TenantAdminEmptyState(
          title: 'No roles available',
          message:
              'Tenant context did not return any roles. A dedicated role list API is not wired yet.',
        ),
      );
    }

    final dataState = ref.watch(rolePermissionsDataProvider(selectedRoleId));
    final uiState =
        ref.watch(rolePermissionsUiControllerProvider(selectedRoleId));
    final canUpdate = ref.watch(rolePermissionsCanUpdateProvider);

    ref.listen(
      rolePermissionsDataProvider(selectedRoleId),
      (previous, next) {
        next.whenData((data) {
          ref
              .read(
                rolePermissionsUiControllerProvider(selectedRoleId).notifier,
              )
              .initializeFromRolePermissions(data.rolePermissions);
        });
      },
    );

    return TenantAdminPageScaffold(
      title: 'Roles & Permissions',
      subtitle: 'Assign tenant-entitled permissions to a role.',
      actions: [
        if (canUpdate) ...[
          TenantAdminSecondaryButton(
            label: 'Configure Role Access',
            icon: Icons.add,
            onPressed: () => context
                .go('/tenant-admin/roles-permissions/create/select-role'),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          TenantAdminPrimaryButton(
            label: 'Save changes',
            loading: uiState.isSaving,
            onPressed: uiState.isSaving
                ? null
                : () => ref
                    .read(
                      rolePermissionsUiControllerProvider(selectedRoleId)
                          .notifier,
                    )
                    .save(selectedRoleId),
          ),
        ]
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoleSelector(
            roles: availableRoles,
            selectedRoleId: selectedRoleId,
            onChanged: (roleId) {
              ref.read(rolePermissionsSelectedRoleIdProvider.notifier).state =
                  roleId;
              context.go('/tenant-admin/roles-permissions/$roleId');
            },
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (uiState.saveMessage != null) ...[
            _FeedbackBanner(
              message: uiState.saveMessage!,
              isError: false,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
          ],
          if (uiState.saveError != null) ...[
            _FeedbackBanner(
              message: uiState.saveError!,
              isError: true,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
          ],
          dataState.when(
            loading: () => const TenantAdminLoadingSkeleton(rowCount: 8),
            error: (error, stackTrace) => TenantAdminErrorState(
              title: 'Unable to load permission catalog',
              message: 'Please try again.',
              onRetry: () =>
                  ref.invalidate(rolePermissionsDataProvider(selectedRoleId)),
            ),
            data: (data) {
              final filteredModules = filterPermissionCatalog(
                catalog: data.catalog,
                searchQuery: uiState.searchQuery,
                scopeFilter: uiState.scopeFilter,
                moduleFilter: uiState.moduleFilter,
              );

              if (filteredModules.isEmpty) {
                return const TenantAdminEmptyState(
                  title: 'No permissions match',
                  message:
                      'Try clearing the search or filters to see entitled permissions.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterBar(
                    searchQuery: uiState.searchQuery,
                    scopeFilter: uiState.scopeFilter,
                    moduleFilter: uiState.moduleFilter,
                    modules: data.catalog.modules,
                    permissionCount: countPermissions(filteredModules),
                    onSearchChanged: (value) => ref
                        .read(
                          rolePermissionsUiControllerProvider(selectedRoleId)
                              .notifier,
                        )
                        .setSearchQuery(value),
                    onScopeChanged: (value) => ref
                        .read(
                          rolePermissionsUiControllerProvider(selectedRoleId)
                              .notifier,
                        )
                        .setScopeFilter(value),
                    onModuleChanged: (value) => ref
                        .read(
                          rolePermissionsUiControllerProvider(selectedRoleId)
                              .notifier,
                        )
                        .setModuleFilter(value),
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Text(
                    '${data.rolePermissions.roleName} (${data.rolePermissions.roleCode})',
                    style: TenantAdminTextStyles.sectionTitle(context),
                  ),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  Text(
                    '${uiState.selectedCodes.length} permission(s) selected',
                    style: TenantAdminTextStyles.muted(context),
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  ...filteredModules.map(
                    (module) => _ModuleSection(
                      module: module,
                      selectedCodes: uiState.selectedCodes,
                      canUpdate: canUpdate,
                      onToggle: (code) => ref
                          .read(
                            rolePermissionsUiControllerProvider(selectedRoleId)
                                .notifier,
                          )
                          .togglePermission(code),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.roles,
    required this.selectedRoleId,
    required this.onChanged,
  });

  final List<TenantAdminRoleOption> roles;
  final String selectedRoleId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: selectedRoleId,
        decoration: InputDecoration(
          labelText: 'Role',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
        ),
        items: [
          for (final role in roles)
            DropdownMenuItem<String>(
              value: role.id,
              child: Text(role.name),
            ),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchQuery,
    required this.scopeFilter,
    required this.moduleFilter,
    required this.modules,
    required this.permissionCount,
    required this.onSearchChanged,
    required this.onScopeChanged,
    required this.onModuleChanged,
  });

  final String searchQuery;
  final String scopeFilter;
  final String? moduleFilter;
  final List<PermissionCatalogModule> modules;
  final int permissionCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onScopeChanged;
  final ValueChanged<String?> onModuleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: searchQuery,
          decoration: const InputDecoration(
            labelText: 'Search',
            hintText: 'Permission code or name',
            border: OutlineInputBorder(),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        Wrap(
          spacing: TenantAdminSpacing.md,
          runSpacing: TenantAdminSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: scopeFilter.isEmpty ? '' : scopeFilter,
                decoration: const InputDecoration(
                  labelText: 'Scope',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '', child: Text('All scopes')),
                  DropdownMenuItem(value: 'platform', child: Text('Platform')),
                  DropdownMenuItem(value: 'tenant', child: Text('Tenant')),
                  DropdownMenuItem(value: 'pos', child: Text('POS')),
                ],
                onChanged: (value) => onScopeChanged(value ?? ''),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: moduleFilter,
                decoration: const InputDecoration(
                  labelText: 'Module',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All modules'),
                  ),
                  for (final module in modules)
                    DropdownMenuItem<String?>(
                      value: module.code,
                      child: Text(module.name),
                    ),
                ],
                onChanged: onModuleChanged,
              ),
            ),
            Chip(label: Text('$permissionCount permission(s)')),
          ],
        ),
      ],
    );
  }
}

class _ModuleSection extends StatelessWidget {
  const _ModuleSection({
    required this.module,
    required this.selectedCodes,
    required this.canUpdate,
    required this.onToggle,
  });

  final PermissionCatalogModule module;
  final Set<String> selectedCodes;
  final bool canUpdate;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(module.name),
        subtitle: Text('${module.code} · ${module.scope}'),
        children: [
          for (final feature in module.features)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.lg,
                vertical: TenantAdminSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.name,
                    style: TenantAdminTextStyles.sectionTitle(context),
                  ),
                  Text(
                    feature.code,
                    style: TenantAdminTextStyles.muted(context),
                  ),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  for (final permission in feature.permissions)
                    CheckboxListTile(
                      value: selectedCodes.contains(permission.code),
                      onChanged:
                          canUpdate ? (_) => onToggle(permission.code) : null,
                      title: Text(permission.name),
                      subtitle: Text(permission.code),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: isError
            ? TenantAdminColors.danger.withValues(alpha: 0.08)
            : TenantAdminColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: isError ? TenantAdminColors.danger : TenantAdminColors.success,
        ),
      ),
      child: Text(message),
    );
  }
}
