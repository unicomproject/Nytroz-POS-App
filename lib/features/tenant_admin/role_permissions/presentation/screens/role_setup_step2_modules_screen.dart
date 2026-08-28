import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/role_setup_wizard_provider.dart';
import '../widgets/role_setup_components.dart';
import 'role_setup_shell.dart';

class RoleSetupStep2ModulesScreen extends ConsumerWidget {
  const RoleSetupStep2ModulesScreen({super.key});

  static const _moduleIcons = <String, IconData>{
    'dashboard': Icons.dashboard_outlined,
    'outlets': Icons.store_outlined,
    'tills': Icons.point_of_sale_outlined,
    'users': Icons.people_outline,
    'products': Icons.inventory_2_outlined,
    'inventory': Icons.warehouse_outlined,
    'sales': Icons.receipt_long_outlined,
    'sales_pos': Icons.receipt_long_outlined,
    'reports': Icons.bar_chart_outlined,
    'roles-access': Icons.admin_panel_settings_outlined,
    'online-store': Icons.shopping_bag_outlined,
    'online_store': Icons.shopping_bag_outlined,
    'settings': Icons.settings_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleSetupWizardProvider);
    final controller = ref.read(roleSetupWizardProvider.notifier);
    final catalog = state.catalog;

    return RoleSetupShell(
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RoleSetupStepHeader(
              step: 2,
              title: 'Select Modules',
              subtitle:
                  'Choose the available modules this system role can access.',
            ),
            if (state.errorMessage != null) ...[
              RoleSetupWarningBanner(message: state.errorMessage!),
              const SizedBox(height: TenantAdminSpacing.md),
            ],
            Expanded(
              child: catalog == null
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900
                            ? 3
                            : constraints.maxWidth >= 560
                                ? 2
                                : 1;
                        return GridView.builder(
                          itemCount: catalog.modules.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            childAspectRatio: columns == 1 ? 3.6 : 1.45,
                            crossAxisSpacing: TenantAdminSpacing.md,
                            mainAxisSpacing: TenantAdminSpacing.md,
                          ),
                          itemBuilder: (context, index) {
                            final module = catalog.modules[index];
                            final assignable =
                                controller.canConfigureModule(module);
                            final blockedReasons = module.features
                                .expand((feature) => feature.permissions)
                                .map((permission) => permission.blockedReason)
                                .whereType<String>();
                            final blockedReason = blockedReasons.isEmpty
                                ? null
                                : blockedReasons.first;
                            return RoleModuleCard(
                              title: module.name,
                              description: module.description ??
                                  'Manage ${module.name.toLowerCase()} access.',
                              icon: _moduleIcons[module.code] ??
                                  Icons.apps_outlined,
                              isSelected:
                                  state.selectedModules.contains(module.code),
                              isEntitled: module.isActive && assignable,
                              onTap: () => controller.toggleModule(module.code),
                              unavailableMessage: blockedReason,
                            );
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            const RoleSetupInfoBanner(
              message:
                  'Modules and permissions are supplied by the tenant permission catalog.',
            ),
            RoleSetupFooterActions(
              onBack: () {
                controller.previousStep();
                context
                    .go('/tenant-admin/roles-permissions/create/select-role');
              },
              onContinue: () {
                controller.nextStep();
                context
                    .go('/tenant-admin/roles-permissions/create/permissions');
              },
              canContinue: state.selectedModules.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }
}
