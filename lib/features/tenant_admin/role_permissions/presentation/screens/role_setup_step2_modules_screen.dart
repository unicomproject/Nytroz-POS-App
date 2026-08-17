import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/permission_catalog.dart';
import '../providers/role_permissions_providers.dart';
import '../providers/role_setup_wizard_provider.dart';
import '../widgets/role_setup_components.dart';
import 'role_setup_shell.dart';

final wizardPermissionCatalogProvider =
    FutureProvider.autoDispose<PermissionCatalog>((ref) async {
  return ref.watch(getPermissionCatalogProvider)();
});

class RoleSetupStep2ModulesScreen extends ConsumerWidget {
  const RoleSetupStep2ModulesScreen({super.key});

  static const _moduleIcons = <String, IconData>{
    'dashboard': Icons.dashboard,
    'outlets': Icons.store,
    'tills': Icons.point_of_sale,
    'users': Icons.people,
    'products': Icons.inventory,
    'inventory': Icons.warehouse,
    'sales': Icons.receipt,
    'reports': Icons.bar_chart,
    'roles-access': Icons.admin_panel_settings,
    'online-store': Icons.shopping_bag,
    'settings': Icons.settings,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleSetupWizardProvider);
    final controller = ref.read(roleSetupWizardProvider.notifier);
    final catalogState = ref.watch(wizardPermissionCatalogProvider);

    return RoleSetupShell(
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // ── Step Header ──
            const RoleSetupStepHeader(
              step: 2,
              title: 'Select Modules',
              subtitle:
                  'Select the modules this role can access. Only modules available in your subscription are shown.',
            ),

            // ── Module Grid ──
            Expanded(
              child: catalogState.when(
                loading: () =>
                    const TenantAdminLoadingSkeleton(rowCount: 3),
                error: (error, stackTrace) => TenantAdminErrorState(
                  title: 'Failed to load modules',
                  message: 'Please try again.',
                  onRetry: () =>
                      ref.refresh(wizardPermissionCatalogProvider),
                ),
                data: (catalog) {
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: TenantAdminSpacing.md,
                      mainAxisSpacing: TenantAdminSpacing.md,
                    ),
                    itemCount: catalog.modules.length,
                    itemBuilder: (context, index) {
                      final module = catalog.modules[index];
                      final isEntitled = module.isActive;
                      final icon =
                          _moduleIcons[module.code] ?? Icons.apps;

                      return RoleModuleCard(
                        title: module.name,
                        description: module.description ??
                            'Manage ${module.name.toLowerCase()} operations.',
                        icon: icon,
                        isSelected:
                            state.selectedModules.contains(module.code),
                        isEntitled: isEntitled,
                        onTap: () =>
                            controller.toggleModule(module.code),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: TenantAdminSpacing.md),

            // ── Info Banner ──
            const RoleSetupInfoBanner(
              message:
                  'You can change module selection later. Some modules are required and cannot be disabled.',
              icon: Icons.info_outline,
            ),

            const SizedBox(height: TenantAdminSpacing.md),

            // ── Footer ──
            RoleSetupFooterActions(
              onBack: () {
                controller.previousStep();
                context.go(
                    '/tenant-admin/roles-permissions/create/select-role');
              },
              onSaveDraft: () {
                controller.saveDraft();
              },
              onContinue: () {
                controller.nextStep();
                context.go(
                    '/tenant-admin/roles-permissions/create/permissions');
              },
              canContinue: state.selectedModules.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }
}
