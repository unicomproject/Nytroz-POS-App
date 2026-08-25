import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../tills/domain/entities/till.dart';
import '../../../tills/presentation/providers/till_providers.dart';
import '../../../users/domain/entities/tenant_user.dart';
import '../../../users/presentation/providers/tenant_user_providers.dart';
import '../../domain/entities/role_assignment.dart';
import '../providers/role_setup_wizard_provider.dart';
import '../widgets/role_setup_components.dart';
import 'role_setup_shell.dart';

final roleSetupUserSearchProvider =
    StateProvider.autoDispose<String>((ref) => '');
final roleSetupOutletSearchProvider =
    StateProvider.autoDispose<String>((ref) => '');

final roleSetupUsersProvider =
    FutureProvider.autoDispose<List<TenantUser>>((ref) async {
  final search = ref.watch(roleSetupUserSearchProvider);
  final result = await ref.watch(getUsersProvider)(
    query: TenantUserListQuery(
      search: search.isEmpty ? null : search,
      page: 1,
      pageSize: 50,
    ),
  );
  return result.items;
});

class RoleSetupStep4AssignmentsScreen extends ConsumerWidget {
  const RoleSetupStep4AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleSetupWizardProvider);
    final controller = ref.read(roleSetupWizardProvider.notifier);
    final users = ref.watch(roleSetupUsersProvider);
    final outlets = ref.watch(tillOutletOptionsProvider);
    final userSearch = ref.watch(roleSetupUserSearchProvider);
    final outletSearch = ref.watch(roleSetupOutletSearchProvider);

    return RoleSetupShell(
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RoleSetupStepHeader(
              step: 4,
              title: 'Assign Users & Access Scope',
              subtitle:
                  'Choose users, then set tenant-wide or selected-outlet access for each user.',
            ),
            if (state.errorMessage != null) ...[
              RoleSetupWarningBanner(message: state.errorMessage!),
              const SizedBox(height: TenantAdminSpacing.md),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final userPanel = _UserPanel(
                    users: users,
                    selectedIds:
                        state.assignments.map((item) => item.userId).toSet(),
                    activeUserId: state.activeAssignmentUserId,
                    search: userSearch,
                    onSearch: (value) => ref
                        .read(roleSetupUserSearchProvider.notifier)
                        .state = value,
                    onToggle: (user) => controller.toggleUser(
                      user.id,
                      fullName: user.fullName,
                      email: user.email,
                    ),
                    onSelect: controller.setActiveAssignmentUser,
                  );
                  final scopePanel = _ScopePanel(
                    assignment: state.activeAssignment,
                    outlets: outlets,
                    search: outletSearch,
                    onSearch: (value) => ref
                        .read(roleSetupOutletSearchProvider.notifier)
                        .state = value,
                    onScopeChanged: controller.setAssignmentScope,
                    onOutletToggle: controller.toggleAssignmentOutlet,
                  );
                  return constraints.maxWidth >=
                          TenantAdminBreakpoints.smallTablet
                      ? Row(
                          children: [
                            Expanded(child: userPanel),
                            const SizedBox(width: TenantAdminSpacing.xl),
                            Expanded(child: scopePanel),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(child: userPanel),
                            const SizedBox(height: TenantAdminSpacing.md),
                            Expanded(child: scopePanel),
                          ],
                        );
                },
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            RoleSetupFooterActions(
              onBack: () {
                controller.previousStep();
                context
                    .go('/tenant-admin/roles-permissions/create/permissions');
              },
              onContinue: () {
                if (state.hasInvalidAssignment) return;
                controller.nextStep();
                context.go('/tenant-admin/roles-permissions/create/review');
              },
              canContinue: !state.hasInvalidAssignment,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserPanel extends StatelessWidget {
  const _UserPanel({
    required this.users,
    required this.selectedIds,
    required this.activeUserId,
    required this.search,
    required this.onSearch,
    required this.onToggle,
    required this.onSelect,
  });

  final AsyncValue<List<TenantUser>> users;
  final Set<String> selectedIds;
  final String? activeUserId;
  final String search;
  final ValueChanged<String> onSearch;
  final void Function(TenantUser user) onToggle;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => _Panel(
        title: 'Assign users',
        child: Column(
          children: [
            TenantAdminSearchField(
              hint: 'Search name, email or staff code',
              onChanged: onSearch,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Expanded(
              child: users.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('Unable to load users.')),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        search.trim().isEmpty
                            ? 'No eligible users are available.'
                            : 'No users found for "${search.trim()}".',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = items[index];
                    final selected = selectedIds.contains(user.id);
                    return ListTile(
                      selected: user.id == activeUserId,
                      selectedTileColor:
                          TenantAdminColors.primary.withValues(alpha: 0.08),
                      leading: Checkbox(
                        value: selected,
                        activeColor: TenantAdminColors.primary,
                        onChanged: (_) => onToggle(user),
                      ),
                      title: Text(user.fullName),
                      subtitle: Text(
                        [
                          user.email,
                          if (user.staffCode?.isNotEmpty == true)
                            user.staffCode!
                        ].join(' • '),
                      ),
                      trailing: Text(user.status),
                      onTap: selected
                          ? () => onSelect(user.id)
                          : () => onToggle(user),
                    );
                  },
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _ScopePanel extends StatelessWidget {
  const _ScopePanel({
    required this.assignment,
    required this.outlets,
    required this.search,
    required this.onSearch,
    required this.onScopeChanged,
    required this.onOutletToggle,
  });

  final RoleAssignment? assignment;
  final AsyncValue<List<OutletOption>> outlets;
  final String search;
  final ValueChanged<String> onSearch;
  final ValueChanged<RoleAccessScopeType> onScopeChanged;
  final ValueChanged<String> onOutletToggle;

  @override
  Widget build(BuildContext context) {
    if (assignment == null) {
      return const _Panel(
        title: 'Access scope',
        child: Center(child: Text('Select a user to configure their scope.')),
      );
    }
    return _Panel(
      title: 'Access scope',
      child: ListView(
        children: [
          RadioListTile<RoleAccessScopeType>(
            value: RoleAccessScopeType.tenantWide,
            groupValue: assignment!.scopeType,
            activeColor: TenantAdminColors.primary,
            title: const Text('Tenant-wide access'),
            subtitle: const Text('User can access all permitted outlets.'),
            onChanged: (value) => onScopeChanged(value!),
          ),
          RadioListTile<RoleAccessScopeType>(
            value: RoleAccessScopeType.selectedOutlets,
            groupValue: assignment!.scopeType,
            activeColor: TenantAdminColors.primary,
            title: const Text('Selected outlets'),
            subtitle: const Text('User can access only the selected outlets.'),
            onChanged: (value) => onScopeChanged(value!),
          ),
          if (assignment!.scopeType == RoleAccessScopeType.selectedOutlets) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            TenantAdminSearchField(
              hint: 'Search outlets',
              onChanged: onSearch,
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            outlets.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(TenantAdminSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(TenantAdminSpacing.md),
                child: Center(child: Text('Unable to load outlets.')),
              ),
              data: (items) {
                final normalizedSearch = search.trim().toLowerCase();
                final filtered = items.where((outlet) {
                  return normalizedSearch.isEmpty ||
                      outlet.name.toLowerCase().contains(normalizedSearch) ||
                      outlet.code.toLowerCase().contains(normalizedSearch);
                }).toList(growable: false);
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(TenantAdminSpacing.md),
                    child: Center(
                      child: Text(
                        normalizedSearch.isEmpty
                            ? 'No active outlets are available.'
                            : 'No outlets found for "${search.trim()}".',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final outlet = filtered[index];
                    return CheckboxListTile(
                      value: assignment!.outletIds.contains(outlet.id),
                      activeColor: TenantAdminColors.primary,
                      title: Text(outlet.name),
                      subtitle: Text(outlet.code),
                      onChanged: (_) => onOutletToggle(outlet.id),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TenantAdminTextStyles.sectionTitle(context)),
            const SizedBox(height: TenantAdminSpacing.md),
            Expanded(child: child),
          ],
        ),
      );
}
