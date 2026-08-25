import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/theme/tenant_admin_motion.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../presentation/widgets/tenant_admin_management_card.dart';
import '../../../presentation/widgets/tenant_admin_pagination.dart';
import '../../../presentation/widgets/tenant_admin_row_action.dart';
import '../../domain/entities/role_list_item.dart';
import '../providers/role_list_visibility_provider.dart';
import '../providers/role_mutation_controller.dart';
import '../providers/roles_list_providers.dart';

class RoleListPanel extends ConsumerWidget {
  const RoleListPanel({
    super.key,
    required this.result,
    required this.visibility,
    required this.isMobile,
    required this.showDetailPanel,
    required this.selectedRoleId,
    required this.onSelect,
  });

  final PaginatedRoleList result;
  final RoleListVisibility visibility;
  final bool isMobile;
  final bool showDetailPanel;
  final String? selectedRoleId;
  final ValueChanged<RoleListItem> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutationState = ref.watch(roleMutationControllerProvider);

    if (result.items.isEmpty) {
      return const TenantAdminDataTable(
        columns: [],
        rows: [],
        emptyTitle: 'No Roles Found',
        emptyMessage: 'No roles match your search criteria.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < TenantAdminBreakpoints.desktop) {
          return Column(
            children: [
              for (final role in result.items) ...[
                _RoleManagementCard(
                  role: role,
                  canEdit: visibility.showEditRole,
                  isLoading: mutationState.isLoading,
                  onView: () => onSelect(role),
                  onEdit: () => context.go('/tenant-admin/roles/${role.id}/edit'),
                  onToggleStatus: () =>
                      _confirmStatusChange(context, ref, role),
                ),
                const SizedBox(height: TenantAdminSpacing.md),
              ],
              if (result.totalPages > 1)
                TenantAdminPaginationBar(
                  currentPage: result.page,
                  pageSize: result.pageSize,
                  totalCount: result.totalCount,
                  itemLabel: 'roles',
                  onPageChanged: (page) {
                    final query = ref.read(rolesListQueryProvider);
                    ref.read(rolesListQueryProvider.notifier).state =
                        query.copyWith(page: page);
                  },
                ),
            ],
          );
        }

        return TenantAdminDataTable(
      columns: const [
        DataColumn(label: Text('ROLE NAME')),
        DataColumn(
          label: SizedBox(
            width: 95,
            child: Text('PERMISSIONS', textAlign: TextAlign.center),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: 60,
            child: Text('USERS', textAlign: TextAlign.center),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: 80,
            child: Text('STATUS', textAlign: TextAlign.center),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: 100,
            child: Text('CREATED', textAlign: TextAlign.center),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: 96,
            child: Text('ACTION', textAlign: TextAlign.center),
          ),
        ),
      ],
      rows: result.items.map((role) {
        final isSelected = role.id == selectedRoleId && showDetailPanel;
        
        return DataRow(
          selected: isSelected,
          onSelectChanged: (_) => onSelect(role),
          color: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return TenantAdminColors.posHomeAccentOrange.withAlpha(20);
            }
            if (states.contains(WidgetState.hovered)) {
              return TenantAdminColors.subtleBackground;
            }
            return null;
          }),
          cells: [
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        role.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                          color: isSelected
                              ? TenantAdminColors.posHomeAccentOrange
                              : TenantAdminColors.bodyText,
                        ),
                      ),
                      if (role.isSystem) ...[
                        const SizedBox(width: TenantAdminSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: TenantAdminColors.mutedText.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SYSTEM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: TenantAdminColors.mutedText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (role.description != null && role.description!.isNotEmpty)
                    Text(
                      role.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TenantAdminColors.mutedText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            DataCell(
              SizedBox(
                width: 95,
                child: Text('${role.permissionCount}', textAlign: TextAlign.center),
              ),
            ),
            DataCell(
              SizedBox(
                width: 60,
                child: Text('${role.userCount}', textAlign: TextAlign.center),
              ),
            ),
            DataCell(
              SizedBox(
                width: 80,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TenantAdminSpacing.md,
                      vertical: TenantAdminSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: role.isActive
                          ? TenantAdminColors.successSurface
                          : TenantAdminColors.dangerSurface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      role.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: role.isActive
                            ? TenantAdminColors.success
                            : TenantAdminColors.danger,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 100,
                child: Text(
                  DateFormat('MMM d, yyyy').format(role.createdAt.toLocal()),
                  style: const TextStyle(color: TenantAdminColors.mutedText),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 96,
                child: _RoleActions(
                  role: role,
                  canEdit: visibility.showEditRole,
                  isLoading: mutationState.isLoading,
                  onView: () => onSelect(role),
                  onEdit: () => context.go('/tenant-admin/roles/${role.id}/edit'),
                  onToggleStatus: () => _confirmStatusChange(context, ref, role),
                ),
              ),
            ),
          ],
        );
      }).toList(),
      showCheckboxColumn: false,
      minWidth: 980,
      footer: result.totalPages > 1
          ? TenantAdminPaginationBar(
              currentPage: result.page,
              pageSize: 5,
              totalCount: result.totalCount,
              onPageChanged: (page) {
                final query = ref.read(rolesListQueryProvider);
                ref.read(rolesListQueryProvider.notifier).state = query.copyWith(page: page);
              },
            )
          : null,
        );
      },
    );
  }

  Future<void> _confirmStatusChange(
    BuildContext context,
    WidgetRef ref,
    RoleListItem role,
  ) async {
    final nextStatus = !role.isActive;
    final action = nextStatus ? 'activate' : 'disable';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${nextStatus ? 'Activate' : 'Disable'} role?'),
        content: Text(
          nextStatus
              ? 'Users assigned to "${role.name}" will regain this role access.'
              : 'Users assigned to "${role.name}" will no longer receive this role access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: nextStatus
                  ? TenantAdminColors.success
                  : TenantAdminColors.danger,
            ),
            child: Text(nextStatus ? 'Activate' : 'Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(roleMutationControllerProvider.notifier)
        .updateRoleStatus(role.id, nextStatus, role.updatedAt);
    if (!context.mounted) return;

    final mutationState = ref.read(roleMutationControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Role ${nextStatus ? 'activated' : 'disabled'} successfully.'
              : mutationState.error ?? 'Unable to $action this role.',
        ),
        backgroundColor:
            success ? TenantAdminColors.success : TenantAdminColors.danger,
      ),
    );
  }
}

class _RoleManagementCard extends StatelessWidget {
  const _RoleManagementCard({
    required this.role,
    required this.canEdit,
    required this.isLoading,
    required this.onView,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final RoleListItem role;
  final bool canEdit;
  final bool isLoading;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) => TenantAdminManagementCard(
        title: role.name,
        badge: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.sm,
            vertical: TenantAdminSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: role.isSystem
                ? TenantAdminColors.subtleBackground
                : TenantAdminColors.secondary,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          ),
          child: Text(
            role.isSystem ? 'SYSTEM' : role.code,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: TenantAdminColors.mutedText,
            ),
          ),
        ),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: TenantAdminColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          ),
          child: const Icon(
            Icons.admin_panel_settings_outlined,
            color: TenantAdminColors.primary,
            size: 28,
          ),
        ),
        metrics: [
          TenantAdminManagementCardMetric(
            label: 'Permissions',
            icon: Icons.key_outlined,
            value: Text('${role.permissionCount}'),
          ),
          TenantAdminManagementCardMetric(
            label: 'Users',
            icon: Icons.people_outline,
            value: Text('${role.userCount}'),
          ),
          TenantAdminManagementCardMetric(
            label: 'Created',
            icon: Icons.calendar_today_outlined,
            value: Text(DateFormat('MMM d, yyyy').format(role.createdAt.toLocal())),
          ),
        ],
        status: TenantAdminAnimatedStatus(
          statusKey: role.isActive,
          child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.md,
            vertical: TenantAdminSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: (role.isActive
                    ? TenantAdminColors.success
                    : TenantAdminColors.danger)
                .withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            role.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: role.isActive
                  ? TenantAdminColors.success
                  : TenantAdminColors.danger,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          ),
        ),
        actions: [
          TenantAdminManagementCardAction(
            label: 'View',
            icon: Icons.visibility_outlined,
            onPressed: onView,
          ),
          if (!role.isSystem && canEdit && !isLoading)
            TenantAdminManagementCardAction(
              label: 'Edit',
              icon: Icons.edit_outlined,
              onPressed: onEdit,
            ),
          if (!role.isSystem && canEdit && !isLoading)
            TenantAdminManagementCardAction(
              label: role.isActive ? 'Disable' : 'Enable',
              icon: role.isActive
                  ? Icons.block_outlined
                  : Icons.check_circle_outline,
              color: role.isActive
                  ? TenantAdminColors.danger
                  : TenantAdminColors.success,
              onPressed: onToggleStatus,
            ),
        ],
        onTap: onView,
      );
}

class _RoleActions extends StatelessWidget {
  const _RoleActions({
    required this.role,
    required this.canEdit,
    required this.isLoading,
    required this.onView,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final RoleListItem role;
  final bool canEdit;
  final bool isLoading;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PopupMenuButton<_RoleAction>(
        tooltip: 'Role actions',
        enabled: !isLoading,
        position: PopupMenuPosition.under,
        constraints: const BoxConstraints(minWidth: 148),
        menuPadding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        ),
        icon: const Icon(Icons.more_vert),
        onSelected: (action) {
          switch (action) {
            case _RoleAction.view:
              onView();
              break;
            case _RoleAction.edit:
              onEdit();
              break;
            case _RoleAction.toggleStatus:
              onToggleStatus();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: _RoleAction.view,
            child: TenantAdminRowActionMenuItem(
              icon: Icons.visibility_outlined,
              label: 'View',
            ),
          ),
          if (!role.isSystem && canEdit) ...[
            const PopupMenuItem(
              value: _RoleAction.edit,
              child: TenantAdminRowActionMenuItem(
                icon: Icons.edit_outlined,
                label: 'Edit',
              ),
            ),
            PopupMenuItem(
              value: _RoleAction.toggleStatus,
              child: TenantAdminRowActionMenuItem(
                icon: role.isActive
                    ? Icons.block_outlined
                    : Icons.check_circle_outline,
                label: role.isActive ? 'Disable' : 'Enable',
                destructive: role.isActive,
                success: !role.isActive,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _RoleAction { view, edit, toggleStatus }
