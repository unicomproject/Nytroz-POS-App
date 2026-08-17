import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/role_setup_wizard_provider.dart';
import '../widgets/role_setup_components.dart';
import 'role_setup_shell.dart';

class RoleSetupStep1RoleScreen extends ConsumerWidget {
  const RoleSetupStep1RoleScreen({super.key});

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
            const RoleSetupStepHeader(
              step: 1,
              title: 'Select Role',
              subtitle:
                  'Choose the role you want to configure permissions for.',
            ),

            // ── Role Cards ──
            Expanded(
              child: ListView(
                children: [
                  RoleTemplateCard(
                    title: 'Tenant Admin',
                    description:
                        'Full access to manage outlets, users, roles, products, inventory, reports and settings.',
                    icon: Icons.admin_panel_settings,
                    isSelected:
                        state.selectedTemplateCode == 'tenant-admin',
                    color: TenantAdminColors.primary,
                    onTap: () => controller.selectTemplate('tenant-admin'),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  RoleTemplateCard(
                    title: 'Super Admin',
                    description:
                        'Advanced access with additional system configuration and tenant management.',
                    icon: Icons.shield,
                    isSelected:
                        state.selectedTemplateCode == 'super-admin',
                    color: TenantAdminColors.primary,
                    onTap: () => controller.selectTemplate('super-admin'),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  RoleTemplateCard(
                    title: 'Cashier',
                    description:
                        'Access to POS operations including sales, orders, customers and till functions.',
                    icon: Icons.point_of_sale,
                    isSelected: state.selectedTemplateCode == 'cashier',
                    color: TenantAdminColors.primary,
                    onTap: () => controller.selectTemplate('cashier'),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xl),

                  // ── Custom Role Details Form ──
                  if (state.selectedTemplateCode.isNotEmpty) ...[
                    const Divider(height: 32, color: TenantAdminColors.border),
                    const Text(
                      'Custom Role Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.md),

                    // Role Name
                    Row(
                      children: const [
                        Text(
                          'Role Name',
                          style: TextStyle(
                            color: TenantAdminColors.bodyText,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text('*', style: TextStyle(color: TenantAdminColors.danger)),
                      ],
                    ),
                    const SizedBox(height: TenantAdminSpacing.sm),
                    TextFormField(
                      key: ValueKey('name_${state.selectedTemplateCode}'),
                      initialValue: state.roleName,
                      onChanged: (val) => controller.setRoleName(val),
                      decoration: InputDecoration(
                        hintText: 'Enter custom role name (e.g., Night Shift Cashier)',
                        hintStyle: const TextStyle(
                          color: TenantAdminColors.mutedText,
                          fontWeight: FontWeight.normal,
                        ),
                        filled: true,
                        fillColor: TenantAdminColors.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                          borderSide: const BorderSide(color: TenantAdminColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                          borderSide: const BorderSide(color: TenantAdminColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: TenantAdminSpacing.lg,
                          vertical: TenantAdminSpacing.md,
                        ),
                      ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.lg),

                    // Description
                    const Text(
                      'Role Description (Optional)',
                      style: TextStyle(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.sm),
                    TextFormField(
                      key: ValueKey('desc_${state.selectedTemplateCode}'),
                      initialValue: state.roleDescription,
                      onChanged: (val) => controller.setRoleDescription(val),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter role description',
                        hintStyle: const TextStyle(
                          color: TenantAdminColors.mutedText,
                          fontWeight: FontWeight.normal,
                        ),
                        filled: true,
                        fillColor: TenantAdminColors.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                          borderSide: const BorderSide(color: TenantAdminColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                          borderSide: const BorderSide(color: TenantAdminColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: TenantAdminSpacing.lg,
                          vertical: TenantAdminSpacing.md,
                        ),
                      ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.xl),
                  ],

                  // ── Info Banner ──
                  const RoleSetupInfoBanner(
                    message:
                        'Permissions will be applied to all users assigned to this role.',
                    icon: Icons.info_outline,
                  ),
                ],
              ),
            ),

            // ── Footer Actions ──
            RoleSetupFooterActions(
              backLabel: 'Cancel',
              onBack: () async {
                if (state.isDirty) {
                  final discard = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Discard role setup?'),
                      content:
                          const Text('Your unsaved changes will be lost.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Continue Editing'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Discard',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (discard != true) return;
                }
                ref.invalidate(roleSetupWizardProvider);
                if (context.mounted) {
                  context.go('/tenant-admin/roles');
                }
              },
              onContinue: () {
                controller.nextStep();
                context.go(
                    '/tenant-admin/roles-permissions/create/modules');
              },
              canContinue: state.selectedTemplateCode.isNotEmpty &&
                  state.roleName != null &&
                  state.roleName!.trim().isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }
}
