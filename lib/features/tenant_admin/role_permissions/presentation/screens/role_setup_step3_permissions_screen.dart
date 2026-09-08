import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/permission_catalog.dart';
import '../providers/role_setup_wizard_provider.dart';
import '../widgets/role_setup_components.dart';
import 'role_setup_shell.dart';

class RoleSetupStep3PermissionsScreen extends ConsumerStatefulWidget {
  const RoleSetupStep3PermissionsScreen({super.key});

  @override
  ConsumerState<RoleSetupStep3PermissionsScreen> createState() =>
      _RoleSetupStep3PermissionsScreenState();
}

class _RoleSetupStep3PermissionsScreenState
    extends ConsumerState<RoleSetupStep3PermissionsScreen> {
  String? _selectedModuleCode;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roleSetupWizardProvider);
    final controller = ref.read(roleSetupWizardProvider.notifier);
    final modules =
        (state.catalog?.modules ?? const <PermissionCatalogModule>[])
            .where((module) => state.selectedModules.contains(module.code))
            .toList(growable: false);
    final activeModule = _activeModule(modules);

    return RoleSetupShell(
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RoleSetupStepHeader(
              step: 3,
              title: 'Configure Permissions',
              subtitle:
                  'Choose individual actions. Unavailable actions remain locked by server policy.',
            ),
            if (state.errorMessage != null) ...[
              RoleSetupWarningBanner(message: state.errorMessage!),
              const SizedBox(height: TenantAdminSpacing.md),
            ],
            Expanded(
              child: modules.isEmpty
                  ? const Center(
                      child: Text(
                          'Select at least one module before configuring permissions.'),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 720;
                        final navigator = _ModuleNavigator(
                          modules: modules,
                          selectedCode: activeModule.code,
                          selectedCodes: state.selectedPermissionCodes,
                          onSelect: (code) =>
                              setState(() => _selectedModuleCode = code),
                        );
                        final permissions = _PermissionPanel(
                          module: activeModule,
                          selectedCodes: state.selectedPermissionCodes,
                          onToggle: controller.togglePermission,
                          onSelectAll: () =>
                              controller.selectAllAssignablePermissions(
                                  activeModule.code),
                        );
                        return compact
                            ? Column(
                                children: [
                                  SizedBox(height: 88, child: navigator),
                                  const SizedBox(height: TenantAdminSpacing.md),
                                  Expanded(child: permissions),
                                ],
                              )
                            : Row(
                                children: [
                                  SizedBox(width: 220, child: navigator),
                                  const SizedBox(width: TenantAdminSpacing.xl),
                                  Expanded(child: permissions),
                                ],
                              );
                      },
                    ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            const RoleSetupInfoBanner(
              message:
                  'The final save revalidates delegation ceiling and tenant feature entitlement.',
            ),
            RoleSetupFooterActions(
              onBack: () {
                controller.previousStep();
                context.go('/tenant-admin/roles-permissions/create/modules');
              },
              onContinue: () {
                controller.nextStep();
                context
                    .go('/tenant-admin/roles-permissions/create/assignments');
              },
              canContinue: state.selectedModules.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }

  PermissionCatalogModule _activeModule(List<PermissionCatalogModule> modules) {
    return modules.firstWhere(
      (module) => module.code == _selectedModuleCode,
      orElse: () => modules.first,
    );
  }
}

class _ModuleNavigator extends StatelessWidget {
  const _ModuleNavigator({
    required this.modules,
    required this.selectedCode,
    required this.selectedCodes,
    required this.onSelect,
  });

  final List<PermissionCatalogModule> modules;
  final String selectedCode;
  final Set<String> selectedCodes;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.vertical,
      itemCount: modules.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: TenantAdminSpacing.xs),
      itemBuilder: (context, index) {
        final module = modules[index];
        final selected = module.code == selectedCode;
        final permissions =
            module.features.expand((feature) => feature.permissions);
        final selectedCount = permissions
            .where((permission) => selectedCodes.contains(permission.code))
            .length;
        final total =
            module.features.expand((feature) => feature.permissions).length;
        return ListTile(
          dense: true,
          selected: selected,
          selectedTileColor: TenantAdminColors.primary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          ),
          title: Text(module.name),
          trailing: Text('$selectedCount/$total'),
          onTap: () => onSelect(module.code),
        );
      },
    );
  }
}

class _PermissionPanel extends StatelessWidget {
  const _PermissionPanel({
    required this.module,
    required this.selectedCodes,
    required this.onToggle,
    required this.onSelectAll,
  });

  final PermissionCatalogModule module;
  final Set<String> selectedCodes;
  final ValueChanged<PermissionCatalogPermission> onToggle;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final permissions =
        module.features.expand((feature) => feature.permissions);
    final selectedCount = permissions
        .where((permission) => selectedCodes.contains(permission.code))
        .length;
    final assignableCount = module.features
        .expand((feature) => feature.permissions)
        .where((permission) => permission.assignable)
        .length;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: TenantAdminColors.border),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${module.name} permissions',
                    style: TenantAdminTextStyles.sectionTitle(context),
                  ),
                ),
                Text('$selectedCount selected'),
                const SizedBox(width: TenantAdminSpacing.md),
                TextButton(
                  onPressed: assignableCount == 0 ? null : onSelectAll,
                  child: const Text('Select available'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                for (final feature in module.features) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TenantAdminSpacing.md,
                      TenantAdminSpacing.md,
                      TenantAdminSpacing.md,
                      TenantAdminSpacing.xs,
                    ),
                    child: Text(
                      feature.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  for (final permission in feature.permissions)
                    CheckboxListTile(
                      value: selectedCodes.contains(permission.code),
                      onChanged: permission.assignable
                          ? (_) => onToggle(permission)
                          : null,
                      activeColor: TenantAdminColors.primary,
                      title: Text(permission.name),
                      subtitle: Text(
                        permission.assignable
                            ? permission.description ?? permission.code
                            : permission.blockedReason ??
                                'This permission cannot be delegated to this role.',
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
