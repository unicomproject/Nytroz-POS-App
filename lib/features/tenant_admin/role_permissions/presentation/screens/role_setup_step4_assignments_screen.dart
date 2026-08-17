// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../domain/entities/role_assignment.dart';
import '../../../users/domain/entities/tenant_user.dart';
import '../../../users/presentation/providers/tenant_user_providers.dart';
import '../../../presentation/providers/tenant_admin_context_provider.dart';
import '../providers/role_setup_wizard_provider.dart';
import '../widgets/role_setup_components.dart';
import 'role_setup_shell.dart';

// Local search query provider for Step 4 to avoid messing up main screen's state
final wizardUserSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// Local user list provider for Step 4
final wizardUserListProvider = FutureProvider.autoDispose<List<TenantUser>>((ref) async {
  final queryText = ref.watch(wizardUserSearchQueryProvider);
  final getUsers = ref.watch(getUsersProvider);
  
  final result = await getUsers(
    query: TenantUserListQuery(
      search: queryText.isEmpty ? null : queryText,
      page: 1,
      pageSize: 50,
    ),
  );
  return result.items;
});

// Local outlet search query provider for Step 4
final wizardOutletSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class RoleSetupStep4AssignmentsScreen extends ConsumerStatefulWidget {
  const RoleSetupStep4AssignmentsScreen({super.key});

  @override
  ConsumerState<RoleSetupStep4AssignmentsScreen> createState() =>
      _RoleSetupStep4AssignmentsScreenState();
}

class _RoleSetupStep4AssignmentsScreenState
    extends ConsumerState<RoleSetupStep4AssignmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roleSetupWizardProvider);
    final controller = ref.read(roleSetupWizardProvider.notifier);

    // Users and search states
    final usersState = ref.watch(wizardUserListProvider);
    final userSearchText = ref.watch(wizardUserSearchQueryProvider);
    
    // Outlets and search states
    final outletContext = ref.watch(tenantAdminContextProvider).valueOrNull;
    final outletSearchText = ref.watch(wizardOutletSearchQueryProvider);

    final allOutlets = outletContext?.outletScope ?? [];
    final filteredOutlets = allOutlets.where((outlet) {
      if (outletSearchText.isEmpty) return true;
      final term = outletSearchText.toLowerCase();
      return outlet.outletName.toLowerCase().contains(term) ||
          outlet.outletId.toLowerCase().contains(term);
    }).toList();

    return RoleSetupShell(
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // ── Step Header ──
            const RoleSetupStepHeader(
              step: 4,
              title: 'Assign Users & Access Scope',
              subtitle:
                  'Assign this role to specific users and determine whether they have access tenant-wide or only for selected outlets.',
            ),

            // ── LayoutBuilder for Dual Panel ──
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;

                  final leftPanel = _buildLeftUserPanel(
                    context,
                    state: state,
                    controller: controller,
                    usersState: usersState,
                    userSearchText: userSearchText,
                  );

                  final rightPanel = _buildRightScopePanel(
                    context,
                    state: state,
                    controller: controller,
                    filteredOutlets: filteredOutlets,
                    outletSearchText: outletSearchText,
                    isWide: isWide,
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 5, child: leftPanel),
                        VerticalDivider(
                          width: TenantAdminSpacing.xl * 2,
                          thickness: 1,
                          color: TenantAdminColors.border,
                        ),
                        Expanded(flex: 5, child: rightPanel),
                      ],
                    );
                  } else {
                    return ListView(
                      children: [
                        SizedBox(height: 400, child: leftPanel),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.lg),
                          child: Divider(),
                        ),
                        rightPanel,
                      ],
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: TenantAdminSpacing.md),

            // ── Info Banner ──
            const RoleSetupInfoBanner(
              message:
                  'Access scope will apply to all selected users. Users with outlet-specific access can only view data within their assigned scope.',
              icon: Icons.info_outline,
            ),

            const SizedBox(height: TenantAdminSpacing.md),

            // ── Footer ──
            RoleSetupFooterActions(
              onBack: () {
                controller.previousStep();
                context.go('/tenant-admin/roles-permissions/create/permissions');
              },
              onSaveDraft: () {
                controller.saveDraft();
              },
              onContinue: () {
                controller.nextStep();
                context.go('/tenant-admin/roles-permissions/create/review');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftUserPanel(
    BuildContext context, {
    required RoleSetupWizardState state,
    required RoleSetupWizardController controller,
    required AsyncValue<List<TenantUser>> usersState,
    required String userSearchText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Users',
          style: TenantAdminTextStyles.sectionTitle(context),
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        
        // Search users input
        TenantAdminSearchField(
          hint: 'Search users by name, email or staff code...',
          value: userSearchText,
          onChanged: (val) {
            ref.read(wizardUserSearchQueryProvider.notifier).state = val;
          },
        ),
        const SizedBox(height: TenantAdminSpacing.md),

        // Users List
        Expanded(
          child: usersState.when(
            loading: () => const TenantAdminLoadingSkeleton(rowCount: 5),
            error: (e, st) => TenantAdminErrorState(
              title: 'Failed to load users',
              message: 'Please try again.',
              onRetry: () => ref.refresh(wizardUserListProvider),
            ),
            data: (users) {
              if (users.isEmpty) {
                return const Center(
                  child: Text('No users match search criteria.'),
                );
              }
              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isSelected = state.selectedUserIds.contains(user.id);
                  final isActive = user.status.toLowerCase() == 'active';

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => controller.toggleUser(user.id),
                    activeColor: TenantAdminColors.primary,
                    title: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: TenantAdminColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: TenantAdminColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: TenantAdminSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                user.email,
                                style: TenantAdminTextStyles.muted(context).copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? TenantAdminColors.successSurface
                            : TenantAdminColors.dangerSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        user.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? TenantAdminColors.success
                              : TenantAdminColors.danger,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Selected user chips section
        if (state.selectedUserIds.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: TenantAdminSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Users (${state.selectedUserIds.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              TextButton(
                onPressed: () => controller.clearAllUsers(),
                child: const Text('Clear All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: state.selectedUserIds.map((userId) {
              return Chip(
                label: Text(userId, style: const TextStyle(fontSize: 11)),
                onDeleted: () => controller.toggleUser(userId),
                backgroundColor: TenantAdminColors.subtleBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRightScopePanel(
    BuildContext context, {
    required RoleSetupWizardState state,
    required RoleSetupWizardController controller,
    required List<dynamic> filteredOutlets,
    required String outletSearchText,
    required bool isWide,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Access Scope',
          style: TenantAdminTextStyles.sectionTitle(context),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'Define the access scope for the selected users.',
          style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 13),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),

        // Scope Radio Group
        RadioListTile<RoleAccessScopeType>(
          title: const Text('Tenant-wide access', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: const Text('Users can access all permitted outlets.', style: TextStyle(fontSize: 12)),
          value: RoleAccessScopeType.tenantWide,
          groupValue: state.accessScopeType,
          activeColor: TenantAdminColors.primary,
          onChanged: (val) {
            if (val != null) controller.setAccessScope(val);
          },
        ),
        RadioListTile<RoleAccessScopeType>(
          title: const Text('Selected outlets', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: const Text('Users can access only the selected outlets.', style: TextStyle(fontSize: 12)),
          value: RoleAccessScopeType.selectedOutlets,
          groupValue: state.accessScopeType,
          activeColor: TenantAdminColors.primary,
          onChanged: (val) {
            if (val != null) controller.setAccessScope(val);
          },
        ),

        // Outlet checklist (when Selected Outlets is chosen)
        if (state.accessScopeType == RoleAccessScopeType.selectedOutlets) ...[
          const SizedBox(height: TenantAdminSpacing.lg),
          const Divider(),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            'Select Outlets',
            style: TenantAdminTextStyles.sectionTitle(context).copyWith(fontSize: 14),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          TenantAdminSearchField(
            hint: 'Search outlets by name or code...',
            value: outletSearchText,
            onChanged: (val) {
              ref.read(wizardOutletSearchQueryProvider.notifier).state = val;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          isWide
              ? Expanded(
                  child: ListView.separated(
                    itemCount: filteredOutlets.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final outlet = filteredOutlets[index];
                      final isChecked = state.selectedOutletIds.contains(outlet.outletId);

                      return CheckboxListTile(
                        title: Text(outlet.outletName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        subtitle: Text(outlet.outletId, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                        value: isChecked,
                        onChanged: (_) => controller.toggleOutlet(outlet.outletId),
                        activeColor: TenantAdminColors.primary,
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  ),
                )
              : SizedBox(
                  height: 300,
                  child: ListView.separated(
                    itemCount: filteredOutlets.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final outlet = filteredOutlets[index];
                      final isChecked = state.selectedOutletIds.contains(outlet.outletId);

                      return CheckboxListTile(
                        title: Text(outlet.outletName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        subtitle: Text(outlet.outletId, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                        value: isChecked,
                        onChanged: (_) => controller.toggleOutlet(outlet.outletId),
                        activeColor: TenantAdminColors.primary,
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  ),
                ),
        ] else if (isWide)
          const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}
