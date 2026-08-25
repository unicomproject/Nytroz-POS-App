import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/role_setup_wizard_provider.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/role_list_visibility_provider.dart';
import '../providers/roles_list_providers.dart';
import '../widgets/role_details_side_panel.dart';
import '../widgets/role_list_panel.dart';

class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  static const _detailPanelBreakpoint = 750.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(roleListVisibilityProvider);
    final rolesState = ref.watch(rolesListProvider);
    final selectedRoleId = ref.watch(selectedRoleIdProvider);
    final query = ref.watch(rolesListQueryProvider);

    ref.listen<AsyncValue<dynamic>>(rolesListProvider, (previous, next) {
      next.whenData((result) {
        if (result == null) return;
        final selectedId = ref.read(selectedRoleIdProvider);
        final hasSelection = result.items.any((role) => role.id == selectedId);
        if (selectedId != null && !hasSelection) {
          ref.read(selectedRoleIdProvider.notifier).state = null;
        }
      });
    });

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Roles & Access',
        subtitle: 'Manage user roles and their associated permissions.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Roles & Access',
        subtitle: 'Manage user roles and their associated permissions.',
        child: TenantAdminErrorState(
          title: 'Unable to load roles',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(roleListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Roles',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view roles.',
            ),
          );
        }

        return rolesState.when(
          loading: () => const TenantAdminPageScaffold(
            title: 'Roles & Access',
            subtitle: 'Manage user roles and their associated permissions.',
            child: TenantAdminLoadingSkeleton(rowCount: 8),
          ),
          error: (error, stackTrace) => TenantAdminPageScaffold(
            title: 'Roles & Access',
            subtitle: 'Manage user roles and their associated permissions.',
            child: TenantAdminErrorState(
              title: 'Unable to load roles',
              message: 'Please try again.',
              onRetry: () => ref.refresh(rolesListProvider),
            ),
          ),
          data: (result) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile =
                    constraints.maxWidth < TenantAdminBreakpoints.smallTablet;
                final showDetailPanel =
                    constraints.maxWidth >= _detailPanelBreakpoint;

                return TenantAdminPageScaffold(
                  title: 'Roles & Access',
                  subtitle:
                      'Manage user roles and their associated permissions.',
                  actions: [
                    if (visibility.showCreateCustomRole)
                          _CreateCustomRoleButton(
                            onPressed: () =>
                                context.go('/tenant-admin/roles/add'),
                          ),
                    if (visibility.showCreateCustomRole &&
                        visibility.showConfigureRole)
                      const SizedBox(width: TenantAdminSpacing.md),
                    if (visibility.showConfigureRole)
                          _RolesAddButton(
                            onPressed: () => context.go(
                                '/tenant-admin/roles-permissions/create/select-role'),
                          ),
                  ],
                  scrollable: !showDetailPanel,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RolesListControls(
                        isMobile: isMobile,
                        statusFilter: query.status ?? '',
                      ),
                      const SizedBox(height: TenantAdminSpacing.xl),
                      if (showDetailPanel)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: selectedRoleId == null ? 100 : 64,
                                child: SingleChildScrollView(
                                  child: RoleListPanel(
                                    result: result,
                                    visibility: visibility,
                                    isMobile: isMobile,
                                    showDetailPanel: true,
                                    selectedRoleId: selectedRoleId,
                                    onSelect: (role) => ref
                                        .read(selectedRoleIdProvider.notifier)
                                        .state = role.id,
                                  ),
                                ),
                              ),
                              if (selectedRoleId != null) ...[
                                const VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  color: TenantAdminColors.border,
                                ),
                                Expanded(
                                  flex: 36,
                                  child: RoleDetailsSidePanel(
                                    roleId: selectedRoleId,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      else
                        RoleListPanel(
                          result: result,
                          visibility: visibility,
                          isMobile: isMobile,
                          showDetailPanel: false,
                          selectedRoleId: selectedRoleId,
                          onSelect: (role) {
                            ref.read(selectedRoleIdProvider.notifier).state =
                                role.id;
                            if (isMobile) {
                              context.go('/tenant-admin/roles/${role.id}');
                            }
                          },
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CreateCustomRoleButton extends StatelessWidget {
  const _CreateCustomRoleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Create Custom Role'),
      style: FilledButton.styleFrom(
        backgroundColor: TenantAdminColors.posHomeAccentOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size(140, TenantAdminContentTokens.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RolesAddButton extends ConsumerWidget {
  const _RolesAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () {
        ref.invalidate(roleSetupWizardProvider);
        onPressed();
      },
      icon: const Icon(Icons.add),
      label: const Text('Configure Role Access'),
      style: OutlinedButton.styleFrom(
        foregroundColor: TenantAdminColors.posHomeAccentOrange,
        side: const BorderSide(color: TenantAdminColors.posHomeAccentOrange),
        minimumSize: const Size(140, TenantAdminContentTokens.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RolesListControls extends ConsumerWidget {
  const _RolesListControls({
    required this.isMobile,
    required this.statusFilter,
  });

  final bool isMobile;
  final String statusFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchField = TenantAdminSearchField(
      hint: 'Search roles by name or code...',
      value: ref.watch(rolesListQueryProvider).search ?? '',
      onChanged: (value) {
        final query = ref.read(rolesListQueryProvider);
        ref.read(rolesListQueryProvider.notifier).state =
            query.copyWith(search: value, page: 1);
      },
    );

    final filters = DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        ),
        child: DropdownButton<String>(
          value: statusFilter.isEmpty ? '' : statusFilter,
          icon: const Icon(Icons.filter_list),
          onChanged: (String? newValue) {
            final query = ref.read(rolesListQueryProvider);
            ref.read(rolesListQueryProvider.notifier).state = query.copyWith(
                status: newValue == '' ? null : newValue, page: 1);
          },
          items: const [
            DropdownMenuItem(value: '', child: Text('All Statuses')),
            DropdownMenuItem(value: 'Active', child: Text('Active')),
            DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: TenantAdminSpacing.md),
          filters,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: TenantAdminSpacing.lg),
        filters,
      ],
    );
  }
}
