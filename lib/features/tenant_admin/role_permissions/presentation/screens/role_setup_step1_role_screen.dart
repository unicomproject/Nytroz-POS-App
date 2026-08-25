import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/role_setup_wizard_provider.dart';
import '../widgets/role_setup_components.dart';
import 'role_setup_shell.dart';

class RoleSetupStep1RoleScreen extends ConsumerStatefulWidget {
  const RoleSetupStep1RoleScreen({super.key});

  @override
  ConsumerState<RoleSetupStep1RoleScreen> createState() =>
      _RoleSetupStep1RoleScreenState();
}

class _RoleSetupStep1RoleScreenState
    extends ConsumerState<RoleSetupStep1RoleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(roleSetupWizardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roleSetupWizardProvider);
    final controller = ref.read(roleSetupWizardProvider.notifier);

    return RoleSetupShell(
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RoleSetupStepHeader(
              step: 1,
              title: 'Select Role',
              subtitle: 'Choose an existing system role to configure.',
            ),
            if (state.errorMessage != null) ...[
              RoleSetupWarningBanner(message: state.errorMessage!),
              const SizedBox(height: TenantAdminSpacing.md),
            ],
            Expanded(
              child: state.isLoading && state.availableRoles.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: state.availableRoles.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: TenantAdminSpacing.md),
                      itemBuilder: (context, index) {
                        final role = state.availableRoles[index];
                        final selected = state.selectedRole?.id == role.id;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RoleTemplateCard(
                              title: role.name,
                              description: role.description ??
                                  'Configure access for this system role.',
                              icon: role.code == 'CASHIER'
                                  ? Icons.point_of_sale_outlined
                                  : Icons.admin_panel_settings_outlined,
                              isSelected: selected,
                              color: TenantAdminColors.primary,
                              onTap: role.isActive
                                  ? () => controller.selectRole(role)
                                  : () {},
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: TenantAdminSpacing.xl,
                                top: TenantAdminSpacing.sm,
                              ),
                              child: Wrap(
                                spacing: TenantAdminSpacing.sm,
                                runSpacing: TenantAdminSpacing.xs,
                                children: [
                                  _RoleBadge(
                                    label:
                                        role.isSystem ? 'System role' : 'Role',
                                  ),
                                  _RoleBadge(
                                    label:
                                        role.isActive ? 'Active' : 'Inactive',
                                    color: role.isActive
                                        ? TenantAdminColors.success
                                        : TenantAdminColors.mutedText,
                                  ),
                                  _RoleBadge(
                                    label:
                                        '${role.permissionCount} permissions',
                                  ),
                                  _RoleBadge(
                                    label: '${role.userCount} assigned users',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            const RoleSetupInfoBanner(
              message:
                  'Role access is updated atomically when you save the completed setup.',
            ),
            RoleSetupFooterActions(
              backLabel: 'Cancel',
              onBack: () {
                controller.reset();
                context.go('/tenant-admin/roles');
              },
              onContinue: () {
                controller.nextStep();
                context.go('/tenant-admin/roles-permissions/create/modules');
              },
              canContinue: state.hasSelectedRole && !state.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge(
      {required this.label, this.color = TenantAdminColors.primary});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.sm,
          vertical: TenantAdminSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
