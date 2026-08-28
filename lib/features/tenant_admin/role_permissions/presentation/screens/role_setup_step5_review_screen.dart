import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/permission_catalog.dart';
import '../providers/role_setup_wizard_provider.dart';
import '../widgets/role_setup_components.dart';
import 'role_setup_shell.dart';

class RoleSetupStep5ReviewScreen extends ConsumerWidget {
  const RoleSetupStep5ReviewScreen({super.key});

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: RoleSetupStepHeader(
                    step: 5,
                    title: 'Review & Save',
                    subtitle:
                        'Review the role changes before saving the complete access setup.',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    controller.goToStep(1);
                    context.go(
                        '/tenant-admin/roles-permissions/create/select-role');
                  },
                  child: const Text('Edit all'),
                ),
              ],
            ),
            if (state.errorMessage != null) ...[
              RoleSetupWarningBanner(message: state.errorMessage!),
              const SizedBox(height: TenantAdminSpacing.md),
            ],
            if (state.successMessage != null) ...[
              RoleSetupInfoBanner(
                message: state.successMessage!,
                icon: Icons.check_circle_outline,
                color: TenantAdminColors.success,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final modules =
                      _selectedModules(catalog, state.selectedModules);
                  final cards = [
                    RoleReviewSectionCard(
                      title: 'Role',
                      onEdit: () =>
                          _goTo(context, controller, 1, 'select-role'),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.selectedRole?.name ?? 'No role selected',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: TenantAdminSpacing.xs),
                          Text(state.selectedRole?.description ?? ''),
                          const SizedBox(height: TenantAdminSpacing.sm),
                          const _SummaryBadge('System role'),
                        ],
                      ),
                    ),
                    RoleReviewSectionCard(
                      title: 'Modules (${modules.length})',
                      onEdit: () => _goTo(context, controller, 2, 'modules'),
                      content: _BulletList(
                        items: modules.map((module) => module.name).toList(),
                        empty: 'No modules selected.',
                      ),
                    ),
                    RoleReviewSectionCard(
                      title: 'Permissions',
                      onEdit: () =>
                          _goTo(context, controller, 3, 'permissions'),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.selectedPermissionCodes.length} selected permissions',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: TenantAdminSpacing.sm),
                          _BulletList(
                            items: _permissionNames(
                                catalog, state.selectedPermissionCodes),
                            empty: 'No permissions selected.',
                          ),
                        ],
                      ),
                    ),
                    RoleReviewSectionCard(
                      title: 'Assigned users (${state.assignments.length})',
                      onEdit: () =>
                          _goTo(context, controller, 4, 'assignments'),
                      content: _BulletList(
                        items: state.assignments.map((assignment) {
                          final scope =
                              assignment.scopeType.value == 'TENANT_WIDE'
                                  ? 'Tenant-wide'
                                  : '${assignment.outletIds.length} outlet(s)';
                          return '${assignment.fullName ?? assignment.userId} — $scope';
                        }).toList(),
                        empty: 'No users assigned.',
                      ),
                    ),
                  ];
                  final crossAxisCount = constraints.maxWidth >= 880 ? 2 : 1;
                  return GridView.builder(
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisExtent: crossAxisCount == 2 ? 196 : 184,
                      crossAxisSpacing: TenantAdminSpacing.md,
                      mainAxisSpacing: TenantAdminSpacing.md,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) => cards[index],
                  );
                },
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            const RoleSetupInfoBanner(
              message:
                  'Saving revalidates the current access, tenant permissions, outlet ownership and concurrency version.',
            ),
            RoleSetupFooterActions(
              onBack: () {
                controller.previousStep();
                context
                    .go('/tenant-admin/roles-permissions/create/assignments');
              },
              continueLabel: 'Save Role Access',
              isContinuing: state.isSaving,
              onContinue: () async {
                final saved = await controller.saveRoleAccess();
                if (saved && context.mounted) {
                  context.go('/tenant-admin/roles');
                }
              },
              canContinue: state.hasSelectedRole &&
                  !state.hasInvalidAssignment &&
                  !state.isSaving,
            ),
          ],
        ),
      ),
    );
  }

  void _goTo(
    BuildContext context,
    RoleSetupWizardController controller,
    int step,
    String route,
  ) {
    controller.goToStep(step);
    context.go('/tenant-admin/roles-permissions/create/$route');
  }

  List<PermissionCatalogModule> _selectedModules(
    PermissionCatalog? catalog,
    Set<String> selectedCodes,
  ) {
    return (catalog?.modules ?? const <PermissionCatalogModule>[])
        .where((module) => selectedCodes.contains(module.code))
        .toList(growable: false);
  }

  List<String> _permissionNames(
    PermissionCatalog? catalog,
    Set<String> selectedCodes,
  ) {
    return (catalog?.modules ?? const <PermissionCatalogModule>[])
        .expand((module) => module.features)
        .expand((feature) => feature.permissions)
        .where((permission) => selectedCodes.contains(permission.code))
        .map((permission) => permission.name)
        .toList(growable: false);
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.sm,
          vertical: TenantAdminSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: TenantAdminColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: TenantAdminColors.success,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, required this.empty});

  final List<String> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Text(empty);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: TenantAdminSpacing.xs),
        child: Text('• ${items[index]}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
