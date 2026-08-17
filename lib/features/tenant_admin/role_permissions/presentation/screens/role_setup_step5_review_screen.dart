import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/role_assignment.dart';
import '../providers/role_setup_wizard_provider.dart';
import '../widgets/role_setup_components.dart';
import 'role_setup_shell.dart';

class RoleSetupStep5ReviewScreen extends ConsumerWidget {
  const RoleSetupStep5ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleSetupWizardProvider);
    final controller = ref.read(roleSetupWizardProvider.notifier);

    return RoleSetupShell(
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // ── Step Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: RoleSetupStepHeader(
                    step: 5,
                    title: 'Review & Save',
                    subtitle: 'Review the configured role before provisioning it.',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    controller.goToStep(1);
                    context.go('/tenant-admin/roles-permissions/create/select-role');
                  },
                  child: const Text(
                    'Edit All',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: TenantAdminColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            if (state.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
                padding: const EdgeInsets.all(TenantAdminSpacing.md),
                decoration: BoxDecoration(
                  color: TenantAdminColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  border: Border.all(color: TenantAdminColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: TenantAdminColors.danger),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: TenantAdminColors.danger),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Review Grid ──
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  final gridWidget = GridView.count(
                    crossAxisCount: isWide ? 3 : 1,
                    childAspectRatio: isWide ? 1.0 : 2.5,
                    crossAxisSpacing: TenantAdminSpacing.lg,
                    mainAxisSpacing: TenantAdminSpacing.lg,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // 1. Role Details
                      RoleReviewSectionCard(
                        title: 'Role Details',
                        onEdit: () {
                          controller.goToStep(1);
                          context.go('/tenant-admin/roles-permissions/create/select-role');
                        },
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.resolvedRoleName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: TenantAdminSpacing.xs),
                            Text(
                              state.resolvedRoleDescription,
                              style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: TenantAdminSpacing.sm),
                            Row(
                              children: [
                                _buildBadge(state.roleTypeLabel, TenantAdminColors.info),
                                const SizedBox(width: TenantAdminSpacing.sm),
                                _buildBadge('Active', TenantAdminColors.success),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 2. Selected Modules
                      RoleReviewSectionCard(
                        title: 'Modules (${state.selectedModules.length})',
                        onEdit: () {
                          controller.goToStep(2);
                          context.go('/tenant-admin/roles-permissions/create/modules');
                        },
                        content: SizedBox(
                          height: 120,
                          child: state.selectedModules.isEmpty
                              ? const Text('No modules selected.')
                              : ListView(
                                  children: state.selectedModules.map((m) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 2.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline, color: TenantAdminColors.success, size: 14),
                                          const SizedBox(width: 6),
                                          Text(m, style: const TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),

                      // 3. Assigned Users
                      RoleReviewSectionCard(
                        title: 'Assigned Users (${state.selectedUserIds.length})',
                        onEdit: () {
                          controller.goToStep(4);
                          context.go('/tenant-admin/roles-permissions/create/assignments');
                        },
                        content: SizedBox(
                          height: 120,
                          child: state.selectedUserIds.isEmpty
                              ? const Text('No users assigned.')
                              : ListView(
                                  children: state.selectedUserIds.map((userId) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 2.0),
                                      child: Text('• $userId', style: const TextStyle(fontSize: 13)),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),

                      // 4. Access Scope
                      RoleReviewSectionCard(
                        title: 'Access Scope',
                        onEdit: () {
                          controller.goToStep(4);
                          context.go('/tenant-admin/roles-permissions/create/assignments');
                        },
                        content: SizedBox(
                          height: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.accessScopeType == RoleAccessScopeType.tenantWide
                                    ? 'Tenant-wide Access'
                                    : 'Selected Outlets',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              if (state.accessScopeType == RoleAccessScopeType.selectedOutlets)
                                Expanded(
                                  child: ListView(
                                    children: state.selectedOutletIds.map((outletId) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 2.0),
                                        child: Text('• $outletId', style: const TextStyle(fontSize: 12)),
                                      );
                                    }).toList(),
                                  ),
                                )
                              else
                                const Text('Access to all outlets permitted.', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),

                      // 5. Permissions Summary
                      RoleReviewSectionCard(
                        title: 'Permissions Summary',
                        onEdit: () {
                          controller.goToStep(3);
                          context.go('/tenant-admin/roles-permissions/create/permissions');
                        },
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Modules: ${state.selectedModules.length}', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('Total Permissions: ${state.selectedPermissionCodes.length}', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: TenantAdminSpacing.sm),
                            Row(
                              children: [
                                const Text('Access Level: ', style: TextStyle(fontSize: 12)),
                                _buildBadge(
                                  state.accessLevel,
                                  state.accessLevel == 'High'
                                      ? TenantAdminColors.danger
                                      : state.accessLevel == 'Medium'
                                          ? TenantAdminColors.warning
                                          : TenantAdminColors.success,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  return ListView(
                    children: [
                      gridWidget,
                      const SizedBox(height: TenantAdminSpacing.lg),
                      // Warnings Callout
                      const RoleSetupWarningBanner(
                        message: 'After saving, permissions will be applied to all assigned users. You can update permissions anytime.',
                      ),
                      const SizedBox(height: TenantAdminSpacing.sm),
                      RoleSetupInfoBanner(
                        message: 'You can view and edit this role anytime from Roles & Access.',
                        icon: Icons.check_circle_outline,
                        color: TenantAdminColors.success,
                        backgroundColor: TenantAdminColors.successSurface,
                        borderColor: TenantAdminColors.successBorder,
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: TenantAdminSpacing.md),

            // ── Footer ──
            RoleSetupFooterActions(
              continueLabel: 'Create Role',
              isContinuing: state.isSaving,
              canContinue: !state.isSaving,
              onBack: state.isSaving
                  ? null
                  : () {
                      controller.previousStep();
                      context.go('/tenant-admin/roles-permissions/create/assignments');
                    },
              onSaveDraft: state.isSaving
                  ? null
                  : () {
                      controller.saveDraft();
                    },
              onContinue: () async {
                final success = await controller.createRole();
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Role created successfully!')),
                  );
                  ref.invalidate(roleSetupWizardProvider);
                  context.go('/tenant-admin/roles');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
