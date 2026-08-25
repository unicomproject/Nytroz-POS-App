import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/role_details_provider.dart';
import '../providers/role_list_visibility_provider.dart';
import '../providers/role_mutation_controller.dart';
import '../providers/roles_list_providers.dart';

class RoleDetailsSidePanel extends ConsumerWidget {
  const RoleDetailsSidePanel({
    super.key,
    required this.roleId,
    this.isModal = false,
  });

  final String? roleId;
  final bool isModal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (roleId == null) {
      return Container(
        margin: EdgeInsets.zero,
        decoration: isModal ? null : BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.zero,
        ),
        child: const Center(
          child: TenantAdminEmptyState(
            title: 'No Role Selected',
            message: 'Select a role from the list to view its details.',
            icon: Icons.admin_panel_settings_outlined,
          ),
        ),
      );
    }

    final visibility = ref.watch(roleListVisibilityProvider).valueOrNull;
    final detailsState = ref.watch(roleDetailsProvider(roleId!));
    final mutationState = ref.watch(roleMutationControllerProvider);

    return Container(
      margin: EdgeInsets.zero,
      decoration: isModal ? null : BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.zero,
      ),
      child: detailsState.when(
        loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
        error: (error, stackTrace) => TenantAdminErrorState(
          title: 'Error loading role',
          message: 'Could not load role details.',
          onRetry: () => ref.refresh(roleDetailsProvider(roleId!)),
        ),
        data: (role) {
          final isActive = role.status == 'Active';
          final canEdit = visibility?.showEditRole ?? false;
          final canDelete = visibility?.showDeleteRole ?? false;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(TenantAdminSpacing.xl),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: TenantAdminColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: TenantAdminColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  role.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: TenantAdminColors.bodyText,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: TenantAdminSpacing.md,
                                  vertical: TenantAdminSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? TenantAdminColors.successSurface
                                      : TenantAdminColors.dangerSurface,
                                  borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
                                ),
                                child: Text(
                                  role.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? TenantAdminColors.success
                                        : TenantAdminColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: TenantAdminSpacing.xs),
                          Text(
                            role.templateCode,
                            style: const TextStyle(
                              fontSize: 13,
                              color: TenantAdminColors.mutedText,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: TenantAdminColors.mutedText,
                      tooltip: 'Close role details',
                      onPressed: () {
                        if (isModal) {
                          Navigator.of(context).pop();
                        } else {
                          ref.read(selectedRoleIdProvider.notifier).state = null;
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: TenantAdminColors.border),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(TenantAdminSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (role.description != null && role.description!.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TenantAdminColors.bodyText,
                          ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.sm),
                        Text(
                          role.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: TenantAdminColors.bodyText,
                          ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.xl),
                      ],
                      if (mutationState.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(TenantAdminSpacing.md),
                          decoration: BoxDecoration(
                            color: TenantAdminColors.dangerSurface,
                            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                            border: Border.all(color: TenantAdminColors.dangerBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: TenantAdminColors.danger, size: 20),
                              const SizedBox(width: TenantAdminSpacing.sm),
                              Expanded(
                                child: Text(
                                  mutationState.error!,
                                  style: const TextStyle(color: TenantAdminColors.danger, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.xl),
                      ],
                      if (canEdit && !role.isSystem) ...[
                        SizedBox(
                          width: double.infinity,
                          child: TenantAdminPrimaryButton(
                            label: 'Edit Role',
                            icon: Icons.edit_outlined,
                            onPressed: mutationState.isLoading
                                ? null
                                : () => context.go('/tenant-admin/roles/${role.id}/edit'),
                          ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: TenantAdminSecondaryButton(
                            label: isActive ? 'Deactivate Role' : 'Activate Role',
                            icon: isActive ? Icons.block : Icons.check_circle_outline,
                            onPressed: mutationState.isLoading
                                ? null
                                : () => _confirmStatusChange(context, ref, role.id, !isActive),
                          ),
                        ),
                      ],
                      if (canDelete && !role.isSystem) ...[
                        const SizedBox(height: TenantAdminSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete Role'),
                            style: TextButton.styleFrom(
                              foregroundColor: TenantAdminColors.danger,
                              padding: const EdgeInsets.symmetric(
                                vertical: TenantAdminSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                                side: BorderSide(
                                  color: TenantAdminColors.dangerBorder,
                                ),
                              ),
                            ),
                            onPressed: mutationState.isLoading
                                ? null
                                : () => _confirmDelete(context, ref, role.id),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmStatusChange(BuildContext context, WidgetRef ref, String roleId, bool newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus ? 'Activate Role?' : 'Deactivate Role?'),
        content: Text(
          newStatus
              ? 'Users assigned to this role will regain these permissions.'
              : 'Users assigned to this role will lose these permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: newStatus ? TenantAdminColors.success : TenantAdminColors.danger,
            ),
            child: Text(newStatus ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(roleMutationControllerProvider.notifier).updateRoleStatus(roleId, newStatus, null);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String roleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role?'),
        content: const Text(
          'Are you sure you want to delete this role? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: TenantAdminColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(roleMutationControllerProvider.notifier).deleteRole(roleId, null);
      if (success) {
        ref.read(selectedRoleIdProvider.notifier).state = null;
      }
    }
  }
}
