import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/tenant_user_providers.dart';
import '../providers/tenant_user_visibility_provider.dart';
import '../utils/user_list_filters.dart';
import '../widgets/user_filter_chips.dart';
import '../widgets/user_details_side_panel.dart';
import '../widgets/user_list_panel.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  static const _detailPanelBreakpoint = 1200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(userListVisibilityProvider);
    final usersState = ref.watch(userListProvider);
    final statusFilter = ref.watch(userStatusFilterProvider);
    final selectedUserId = ref.watch(selectedUserIdProvider);

    ref.listen<AsyncValue<dynamic>>(userListProvider, (previous, next) {
      next.whenData((result) {
        if (result == null) return;
        final selectedId = ref.read(selectedUserIdProvider);
        final hasSelection = result.items.any((user) => user.id == selectedId);
        ref.read(selectedUserIdProvider.notifier).state = result.items.isEmpty
            ? null
            : hasSelection
                ? selectedId
                : result.items.first.id;
      });
    });

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Users',
        subtitle: 'Manage staff and access across outlets.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Users',
        subtitle: 'Manage staff and access across outlets.',
        child: TenantAdminErrorState(
          title: 'Unable to load users',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(userListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Users',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view users.',
            ),
          );
        }

        return usersState.when(
          loading: () => TenantAdminPageScaffold(
            title: visibility.showTitle ? 'Users' : '',
            subtitle: visibility.showSubtitle
                ? 'Manage staff and access across outlets.'
                : null,
            child: const TenantAdminLoadingSkeleton(rowCount: 8),
          ),
          error: (error, stackTrace) => TenantAdminPageScaffold(
            title: 'Users',
            subtitle: 'Manage staff and access across outlets.',
            child: TenantAdminErrorState(
              title: 'Unable to load users',
              message: 'Please try again.',
              onRetry: () => ref.refresh(userListProvider),
            ),
          ),
          data: (result) {
            if (result == null) {
              return const TenantAdminPageScaffold(
                title: 'No access to Users',
                child: TenantAdminEmptyState(
                  title: 'No access',
                  message: 'You do not have permission to view users.',
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile =
                    constraints.maxWidth < TenantAdminBreakpoints.smallTablet;
                final showDetailPanel =
                    constraints.maxWidth >= _detailPanelBreakpoint;

                return TenantAdminPageScaffold(
                  title: visibility.showTitle ? 'Users' : '',
                  subtitle: visibility.showSubtitle
                      ? 'Manage staff and access across outlets.'
                      : null,
                  actions: visibility.showAddUser
                      ? [
                          _UsersAddButton(
                            onPressed: () =>
                                context.go('/tenant-admin/staff/add'),
                          ),
                        ]
                      : const [],
                  scrollable: !showDetailPanel,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UsersListControls(
                        visibility: visibility,
                        isMobile: isMobile,
                        statusFilter: statusFilter,
                      ),
                      if (visibility.showSearch ||
                          visibility.showStatusFilter ||
                          visibility.showAddUser)
                        const SizedBox(height: TenantAdminSpacing.xl),
                      if (visibility.showList && showDetailPanel)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: showDetailPanel ? 65 : 100,
                                child: SingleChildScrollView(
                                  child: UserListPanel(
                                    result: result,
                                    visibility: visibility,
                                    statusFilter: statusFilter,
                                    isMobile: isMobile,
                                    showDetailPanel: showDetailPanel,
                                    selectedUserId: selectedUserId,
                                    onSelect: (user) => ref
                                        .read(selectedUserIdProvider.notifier)
                                        .state = user.id,
                                  ),
                                ),
                              ),
                              if (showDetailPanel)
                                Expanded(
                                  flex: 35,
                                  child: UserDetailsSidePanel(
                                    userId: selectedUserId,
                                  ),
                                ),
                            ],
                          ),
                        )
                      else if (visibility.showList)
                        UserListPanel(
                          result: result,
                          visibility: visibility,
                          statusFilter: statusFilter,
                          isMobile: isMobile,
                          showDetailPanel: false,
                          selectedUserId: selectedUserId,
                          onSelect: (user) => ref
                              .read(selectedUserIdProvider.notifier)
                              .state = user.id,
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

class _UsersAddButton extends StatelessWidget {
  const _UsersAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Add New User'),
      style: FilledButton.styleFrom(
        backgroundColor: TenantAdminColors.posHomeAccentOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size(160, TenantAdminContentTokens.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _UsersListControls extends ConsumerWidget {
  const _UsersListControls({
    required this.visibility,
    required this.isMobile,
    required this.statusFilter,
  });

  final UserListVisibility visibility;
  final bool isMobile;
  final UserStatusFilter statusFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visibility.showSearch && !visibility.showStatusFilter) {
      return const SizedBox.shrink();
    }

    final searchField = TenantAdminSearchField(
      hint: 'Search users by name, email or phone...',
      value: ref.watch(userSearchProvider),
      onChanged: (value) {
        ref.read(userSearchProvider.notifier).state = value;
        ref.read(userPageProvider.notifier).state = 1;
      },
    );

    final filters = UserFilterChips(selectedFilter: statusFilter);
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (visibility.showSearch) searchField,
          if (visibility.showSearch && visibility.showStatusFilter)
            const SizedBox(height: TenantAdminSpacing.md),
          if (visibility.showStatusFilter) filters,
        ],
      );
    }

    return Row(
      children: [
        if (visibility.showSearch) Expanded(child: searchField),
        if (visibility.showSearch && visibility.showStatusFilter)
          const SizedBox(width: TenantAdminSpacing.lg),
        if (visibility.showStatusFilter) filters,
      ],
    );
  }
}
