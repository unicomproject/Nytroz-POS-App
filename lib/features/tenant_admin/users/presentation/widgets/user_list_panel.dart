import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/tenant_user.dart';
import '../providers/tenant_user_providers.dart';
import '../providers/tenant_user_visibility_provider.dart';
import '../utils/user_list_filters.dart';
import 'user_details_modal.dart';
import 'user_mobile_list.dart';
import 'user_table.dart';

class UserListPanel extends ConsumerWidget {
  const UserListPanel({
    super.key,
    required this.result,
    required this.visibility,
    required this.statusFilter,
    required this.isMobile,
  });

  final TenantUserListResult result;
  final UserListVisibility visibility;
  final UserStatusFilter statusFilter;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCountLabel =
        '${result.totalCount > 0 ? result.totalCount : result.items.length} '
        '${result.totalCount == 1 ? 'User' : 'Users'}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.md,
            ),
            child: _PanelTitle(countLabel: userCountLabel),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          if (result.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
              child: TenantAdminEmptyState(
                title: statusFilter == UserStatusFilter.all
                    ? 'No users found'
                    : 'No matching users',
                message: statusFilter == UserStatusFilter.all
                    ? 'Add your first user to get started.'
                    : 'Try changing the filter or search term.',
                icon: statusFilter == UserStatusFilter.all
                    ? Icons.people_outline
                    : Icons.filter_alt_off_outlined,
                action: statusFilter == UserStatusFilter.all &&
                        visibility.showAddUser
                    ? TenantAdminPrimaryButton(
                        label: 'Add New User',
                        icon: Icons.add,
                        onPressed: () =>
                            context.go('/tenant-admin/staff/add'),
                      )
                    : statusFilter != UserStatusFilter.all
                        ? TenantAdminSecondaryButton(
                            label: 'Clear filters',
                            icon: Icons.clear,
                            onPressed: () => _resetFilters(ref),
                          )
                        : null,
              ),
            )
          else if (isMobile)
            Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              child: UserMobileList(
                users: result.items,
                visibility: visibility,
                onView: (user) => showUserDetailsModal(context, user.id),
                onEdit: (user) =>
                    context.go('/tenant-admin/staff/${user.id}/edit'),
                onDelete: (user) => _confirmDelete(context, ref, user),
              ),
            )
          else
            UserTable(
              users: result.items,
              visibility: visibility,
              onView: (user) => showUserDetailsModal(context, user.id),
              onEdit: (user) =>
                  context.go('/tenant-admin/staff/${user.id}/edit'),
              onDelete: (user) => _confirmDelete(context, ref, user),
            ),
          if (visibility.showPagination && result.totalCount > 0)
            _PaginationFooter(
              page: result.page,
              pageSize: result.pageSize,
              totalCount: result.totalCount,
              onPageChanged: (nextPage) =>
                  ref.read(userPageProvider.notifier).state = nextPage,
            ),
        ],
      ),
    );
  }

  void _resetFilters(WidgetRef ref) {
    ref.read(userStatusFilterProvider.notifier).state = UserStatusFilter.all;
    ref.read(userSearchProvider.notifier).state = '';
    ref.read(userPageProvider.notifier).state = 1;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TenantUser user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user'),
        content: Text(
          'Are you sure you want to disable "${user.fullName}"? '
          'They will no longer be able to sign in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TenantAdminColors.danger,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(deleteUserProvider).call(user.id);
      ref.invalidate(userListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.fullName} has been disabled.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete user.')),
        );
      }
    }
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.countLabel});

  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('User List', style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(width: TenantAdminSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.sm,
            vertical: TenantAdminSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: TenantAdminColors.secondary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            countLabel,
            style: const TextStyle(
              color: TenantAdminColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages =
        pageSize <= 0 ? 1 : (totalCount / pageSize).ceil().clamp(1, 9999);
    final rangeStart = totalCount == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final rangeEnd = (page * pageSize).clamp(0, totalCount);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $rangeStart to $rangeEnd of $totalCount users',
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left, size: 18),
          ),
          Text('$page / $totalPages'),
          IconButton(
            onPressed:
                page < totalPages ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right, size: 18),
          ),
        ],
      ),
    );
  }
}
