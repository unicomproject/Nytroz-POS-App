// ignore_for_file: unused_element

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/tenant_admin_access_codes.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/tenant_admin_context.dart';
import '../../domain/services/tenant_admin_access_checker.dart';
import '../providers/tenant_admin_access_provider.dart';
import '../providers/tenant_admin_context_provider.dart';
import '../theme/tenant_admin_theme.dart';
import '../widgets/tenant_admin_buttons.dart';
import '../widgets/tenant_admin_page_scaffold.dart';
import '../widgets/tenant_admin_states.dart';

class TenantAdminPlaceholderScreen extends ConsumerWidget {
  const TenantAdminPlaceholderScreen({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (title == 'Staff' || title == 'Users') {
      return const _StaffListScreen();
    }

    if (title == 'Add Staff' || title == 'Add New User') {
      return const _AddStaffScreen();
    }

    if (title == 'Roles & Access') {
      return const _RolesAccessScreen();
    }

    if (title == 'Products') {
      return const _ProductListScreen();
    }

    if (title == 'Add Product') {
      return const _AddProductScreen();
    }

    return TenantAdminPageScaffold(
      title: title,
      subtitle:
          subtitle ?? 'This Tenant Admin screen is ready for implementation.',
      child: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

class _RolesAccessScreen extends ConsumerWidget {
  const _RolesAccessScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);
    final contextState = ref.watch(tenantAdminContextProvider);

    return accessState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Roles & Access',
        subtitle: 'Manage roles and permission access for your tenant.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Roles & Access',
        subtitle: 'Manage roles and permission access for your tenant.',
        child: TenantAdminErrorState(
          title: 'Unable to load role access',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(tenantAdminAccessCheckerProvider),
        ),
      ),
      data: (access) {
        final canView = access.canAny(_roleAccessViewPermissions);
        if (!canView) {
          return const TenantAdminPageScaffold(
            title: 'No access to Roles',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view roles and access.',
              icon: Icons.shield_outlined,
            ),
          );
        }

        return contextState.when(
          loading: () => const TenantAdminPageScaffold(
            title: 'Roles & Access',
            subtitle: 'Manage roles and permission access for your tenant.',
            child: TenantAdminLoadingSkeleton(rowCount: 8),
          ),
          error: (error, stackTrace) => TenantAdminPageScaffold(
            title: 'Roles & Access',
            subtitle: 'Manage roles and permission access for your tenant.',
            child: TenantAdminErrorState(
              title: 'Unable to load tenant access',
              message: 'Please try again.',
              onRetry: () => ref.invalidate(tenantAdminContextProvider),
            ),
          ),
          data: (tenantContext) {
            final roleNames = tenantContext.roleNames.isEmpty
                ? const ['Owner']
                : tenantContext.roleNames;
            final permissions = tenantContext.permissions;

            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 820;

                return TenantAdminPageScaffold(
                  title: 'Roles & Access',
                  subtitle:
                      'Manage roles and permission access for your tenant.',
                  actions: [
                    if (access.canAny(_roleAccessManagePermissions))
                      const TenantAdminPrimaryButton(
                        label: 'Add role',
                        icon: Icons.add,
                        onPressed: null,
                      ),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RolesSummaryCards(
                        rolesCount: roleNames.length,
                        permissionsCount: permissions.length,
                        compact: compact,
                      ),
                      const SizedBox(height: TenantAdminSpacing.xl),
                      if (compact)
                        Column(
                          children: [
                            _RolesPanel(roleNames: roleNames),
                            const SizedBox(height: TenantAdminSpacing.lg),
                            _PermissionsPanel(permissions: permissions),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _RolesPanel(roleNames: roleNames),
                            ),
                            const SizedBox(width: TenantAdminSpacing.xl),
                            Expanded(
                              flex: 5,
                              child: _PermissionsPanel(
                                permissions: permissions,
                              ),
                            ),
                          ],
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

class _RolesSummaryCards extends StatelessWidget {
  const _RolesSummaryCards({
    required this.rolesCount,
    required this.permissionsCount,
    required this.compact,
  });

  final int rolesCount;
  final int permissionsCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricData(
        title: 'Total roles',
        value: '$rolesCount',
        subtitle: 'Available in tenant context',
        icon: Icons.shield_outlined,
        color: TenantAdminColors.primary,
      ),
      _MetricData(
        title: 'Permissions',
        value: '$permissionsCount',
        subtitle: 'Granted to this admin',
        icon: Icons.key_outlined,
        color: TenantAdminColors.success,
      ),
      const _MetricData(
        title: 'Access scope',
        value: 'Tenant',
        subtitle: 'Permission-based access',
        icon: Icons.admin_panel_settings_outlined,
        color: TenantAdminColors.pending,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact
            ? 1
            : constraints.maxWidth >= 780
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: TenantAdminSpacing.lg,
            mainAxisSpacing: TenantAdminSpacing.lg,
            childAspectRatio: columns == 1 ? 4.4 : 2.2,
          ),
          itemBuilder: (context, index) => _MetricCard(data: cards[index]),
        );
      },
    );
  }
}

class _RolesPanel extends StatelessWidget {
  const _RolesPanel({required this.roleNames});

  final List<String> roleNames;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Roles', style: TenantAdminTextStyles.sectionTitle(context)),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'Roles returned by tenant context.',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          for (final roleName in roleNames) ...[
            _SelectableTile(
              title: roleName,
              subtitle: 'Can be used for staff access assignment',
              icon: Icons.verified_user_outlined,
              selected: roleName == roleNames.first,
              onTap: () {},
            ),
            if (roleName != roleNames.last)
              const SizedBox(height: TenantAdminSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _PermissionsPanel extends StatelessWidget {
  const _PermissionsPanel({required this.permissions});

  final List<TenantAdminPermission> permissions;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupPermissions(permissions);

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permission catalog',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'Current admin permissions grouped by module.',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (grouped.isEmpty)
            const TenantAdminEmptyState(
              title: 'No permissions available',
              message: 'Tenant context did not return permission data.',
              icon: Icons.key_off_outlined,
            )
          else
            for (final entry in grouped.entries) ...[
              _PermissionGroup(
                moduleName: entry.key,
                permissions: entry.value,
              ),
              if (entry.key != grouped.keys.last)
                const SizedBox(height: TenantAdminSpacing.md),
            ],
        ],
      ),
    );
  }
}

class _PermissionGroup extends StatelessWidget {
  const _PermissionGroup({
    required this.moduleName,
    required this.permissions,
  });

  final String moduleName;
  final List<TenantAdminPermission> permissions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TenantAdminColors.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          moduleName,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text('${permissions.length} permission(s)'),
        children: [
          for (final permission in permissions)
            CheckboxListTile(
              value: true,
              onChanged: null,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(permission.permissionName),
              subtitle: Text(permission.permissionCode),
              dense: true,
            ),
        ],
      ),
    );
  }
}

class _StaffListScreen extends ConsumerWidget {
  const _StaffListScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);

    return accessState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Users',
        subtitle: 'Manage all tenant users and their access.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Users',
        subtitle: 'Manage all tenant users and their access.',
        child: TenantAdminErrorState(
          title: 'Unable to load users access',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(tenantAdminAccessCheckerProvider),
        ),
      ),
      data: (access) {
        final canView = access.canAny(_staffViewPermissions);
        final canCreate = access.canAny(_staffCreatePermissions);
        final usersState = ref.watch(_tenantUsersProvider);

        if (!canView) {
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
            final isCompact = constraints.maxWidth < 860;

            return TenantAdminPageScaffold(
              title: 'Users',
              subtitle: 'Manage all tenant users and their access.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UsersFilterPanel(canCreate: canCreate, compact: isCompact),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  usersState.when(
                    loading: () =>
                        const TenantAdminLoadingSkeleton(rowCount: 8),
                    error: (error, stackTrace) => TenantAdminErrorState(
                      title: 'Unable to load users',
                      message: error is DioException
                          ? messageFromDioException(
                              error,
                              fallback: 'Please try again.',
                            )
                          : 'Please try again.',
                      onRetry: () => ref.invalidate(_tenantUsersProvider),
                    ),
                    data: (result) => _StaffTableCard(
                      access: access,
                      result: result,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

final _tenantUsersProvider = FutureProvider.autoDispose<_TenantUsersResult>((
  ref,
) async {
  final dio = ref.watch(appDioProvider);
  final response = await dio.get<dynamic>(
    '/api/v1/tenant-admin/users',
    queryParameters: const {
      'page': 1,
      'pageSize': 10,
    },
  );

  final root = response.data;
  final payload = root is Map && root['data'] is Map
      ? Map<String, dynamic>.from(root['data'] as Map)
      : root is Map
          ? Map<String, dynamic>.from(root)
          : const <String, dynamic>{};

  final items = payload['items'] is List
      ? (payload['items'] as List)
          .whereType<Map>()
          .map((item) => _ReferenceUser.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(growable: false)
      : const <_ReferenceUser>[];

  return _TenantUsersResult(
    users: items,
    page: _intValue(payload['page'], fallback: 1),
    pageSize: _intValue(payload['pageSize'], fallback: 10),
    totalCount: _intValue(payload['totalCount'], fallback: items.length),
  );
});

class _TenantUsersResult {
  const _TenantUsersResult({
    required this.users,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  final List<_ReferenceUser> users;
  final int page;
  final int pageSize;
  final int totalCount;

  int get rangeStart => totalCount == 0 ? 0 : ((page - 1) * pageSize) + 1;

  int get rangeEnd =>
      totalCount == 0 ? 0 : (page * pageSize).clamp(0, totalCount);
}

class _StaffToolbar extends StatelessWidget {
  const _StaffToolbar({
    required this.canCreate,
    required this.compact,
  });

  final bool canCreate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const search = _SearchField(
      hintText: 'Search staff by name, role or outlet',
    );
    final addButton = TenantAdminPrimaryButton(
      label: 'Add staff',
      icon: Icons.add,
      onPressed: canCreate ? () => context.go('/tenant-admin/staff/add') : null,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          if (canCreate) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            addButton,
          ],
        ],
      );
    }

    return Row(
      children: [
        const Expanded(child: search),
        if (canCreate) ...[
          const SizedBox(width: TenantAdminSpacing.md),
          addButton,
        ],
      ],
    );
  }
}

class _UsersFilterPanel extends StatelessWidget {
  const _UsersFilterPanel({
    required this.canCreate,
    required this.compact,
  });

  final bool canCreate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const search = _SearchField(hintText: 'Search users by name or email...');
    const outlet = _FilterDropdown(
      label: 'Outlet',
      value: 'All Outlets',
      icon: Icons.location_on_outlined,
    );
    const role = _FilterDropdown(
      label: 'Role',
      value: 'All Roles',
      icon: Icons.shield_outlined,
    );
    const status = _FilterDropdown(
      label: 'Status',
      value: 'All Status',
      icon: Icons.radio_button_unchecked,
    );
    final addButton = TenantAdminPrimaryButton(
      label: 'Add New User',
      icon: Icons.add,
      onPressed: canCreate ? () => context.go('/tenant-admin/staff/add') : null,
    );

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: _cardDecoration(),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: TenantAdminSpacing.md),
                outlet,
                const SizedBox(height: TenantAdminSpacing.md),
                role,
                const SizedBox(height: TenantAdminSpacing.md),
                status,
                if (canCreate) ...[
                  const SizedBox(height: TenantAdminSpacing.md),
                  addButton,
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(flex: 2, child: search),
                const SizedBox(width: TenantAdminSpacing.xl),
                const Expanded(child: outlet),
                const SizedBox(width: TenantAdminSpacing.xl),
                const Expanded(child: role),
                const SizedBox(width: TenantAdminSpacing.xl),
                const Expanded(child: status),
                if (canCreate) ...[
                  const SizedBox(width: TenantAdminSpacing.xl),
                  addButton,
                ],
              ],
            ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Container(
          height: 46,
          padding:
              const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: TenantAdminColors.primary),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: TenantAdminColors.bodyText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hintText});

  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: TenantAdminColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.lg,
          vertical: TenantAdminSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          borderSide: const BorderSide(color: TenantAdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          borderSide: const BorderSide(color: TenantAdminColors.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          borderSide: const BorderSide(color: TenantAdminColors.border),
        ),
      ),
    );
  }
}

class _StaffFilterChips extends StatelessWidget {
  const _StaffFilterChips();

  @override
  Widget build(BuildContext context) {
    const filters = [
      _ChipData('All', null),
      _ChipData('Active', null),
      _ChipData('Inactive', null),
      _ChipData('Pending invite', null),
      _ChipData('Needs attention', '0'),
    ];

    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      children: [
        for (var index = 0; index < filters.length; index++)
          _FilterChip(
            label: filters[index].label,
            count: filters[index].count,
            selected: index == 0,
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    this.count,
  });

  final String label;
  final bool selected;
  final String? count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      decoration: BoxDecoration(
        color: selected ? TenantAdminColors.primary : TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              selected ? TenantAdminColors.primary : TenantAdminColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : TenantAdminColors.bodyText,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: TenantAdminSpacing.sm),
            _SmallCountBadge(count: count!),
          ],
        ],
      ),
    );
  }
}

class _SmallCountBadge extends StatelessWidget {
  const _SmallCountBadge({required this.count});

  final String count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: TenantAdminColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count,
        style: const TextStyle(
          color: TenantAdminColors.warning,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StaffSummaryCards extends StatelessWidget {
  const _StaffSummaryCards({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    const cards = [
      _MetricData(
        title: 'Total staff',
        value: '0',
        subtitle: 'Across all outlets',
        icon: Icons.groups_rounded,
        color: TenantAdminColors.primary,
      ),
      _MetricData(
        title: 'Active',
        value: '0',
        subtitle: '0% of total',
        icon: Icons.check_circle_outline,
        color: TenantAdminColors.success,
      ),
      _MetricData(
        title: 'Pending invite',
        value: '0',
        subtitle: '0% of total',
        icon: Icons.mail_outline,
        color: TenantAdminColors.pending,
      ),
      _MetricData(
        title: 'Needs attention',
        value: '0',
        subtitle: '0% of total',
        icon: Icons.warning_amber_rounded,
        color: TenantAdminColors.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact
            ? 1
            : constraints.maxWidth >= 900
                ? 4
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: TenantAdminSpacing.lg,
            mainAxisSpacing: TenantAdminSpacing.lg,
            childAspectRatio: columns == 1
                ? 4.2
                : columns == 2
                    ? 2.2
                    : 1.85,
          ),
          itemBuilder: (context, index) => _MetricCard(data: cards[index]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: data.icon, color: data.color),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data.title, style: TenantAdminTextStyles.muted(context)),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  data.value,
                  style: TenantAdminTextStyles.sectionTitle(context).copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  data.subtitle,
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffTableCard extends StatelessWidget {
  const _StaffTableCard({
    required this.access,
    required this.result,
  });

  final TenantAdminAccessChecker access;
  final _TenantUsersResult result;

  @override
  Widget build(BuildContext context) {
    final canView = access.canAny(_staffDetailPermissions);
    final canEdit = access.canAny(_staffEditPermissions);
    final users = result.users;

    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (users.isEmpty)
            const Padding(
              padding: EdgeInsets.all(TenantAdminSpacing.xl),
              child: TenantAdminEmptyState(
                title: 'No users found',
                message: 'Users from the backend will appear here.',
              ),
            ),
          if (users.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1120),
                child: DataTable(
                  showCheckboxColumn: true,
                  headingRowHeight: 56,
                  dataRowMinHeight: 58,
                  dataRowMaxHeight: 64,
                  headingRowColor: WidgetStateProperty.all(
                    TenantAdminColors.background,
                  ),
                  columnSpacing: 30,
                  horizontalMargin: TenantAdminSpacing.lg,
                  headingTextStyle: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  dataTextStyle: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  columns: const [
                    DataColumn(label: Text('User')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Outlet')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Last Active')),
                    DataColumn(
                      label: Align(
                        alignment: Alignment.centerRight,
                        child: Text('Actions'),
                      ),
                    ),
                  ],
                  rows: [
                    for (final user in users)
                      DataRow(
                        onSelectChanged: canView
                            ? (_) => _showUserDetailsDialog(
                                  context,
                                  user,
                                  canEdit: canEdit,
                                  canDelete: true,
                                )
                            : null,
                        cells: [
                          DataCell(_UserIdentityCell(user: user)),
                          DataCell(Text(user.email)),
                          DataCell(_RoleBadge(label: user.role)),
                          DataCell(Text(user.outlet)),
                          DataCell(_UserStatusBadge(status: user.status)),
                          DataCell(Text(user.lastActive)),
                          DataCell(
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (canEdit)
                                    TenantAdminIconButton(
                                      icon: Icons.edit_outlined,
                                      tooltip: 'Edit',
                                      onPressed: () {},
                                    ),
                                  if (canEdit) ...[
                                    const SizedBox(
                                      width: TenantAdminSpacing.sm,
                                    ),
                                    TenantAdminIconButton(
                                      icon: Icons.delete_outline,
                                      tooltip: 'Delete',
                                      danger: true,
                                      onPressed: () {},
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          const Divider(height: 1, color: TenantAdminColors.border),
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Showing ${result.rangeStart} to ${result.rangeEnd} of ${result.totalCount} users',
                  style: TenantAdminTextStyles.muted(context),
                ),
                const Spacer(),
                const _PaginationButton(
                  icon: Icons.chevron_left,
                  enabled: false,
                ),
                const SizedBox(width: TenantAdminSpacing.sm),
                const _PageNumberButton(label: '1', selected: true),
                const SizedBox(width: TenantAdminSpacing.sm),
                const _PaginationButton(
                  icon: Icons.chevron_right,
                  enabled: true,
                ),
                const SizedBox(width: TenantAdminSpacing.lg),
                const _RowsPerPageButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserIdentityCell extends StatelessWidget {
  const _UserIdentityCell({required this.user});

  final _ReferenceUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _UserAvatar(name: user.name),
        const SizedBox(width: TenantAdminSpacing.md),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              user.role,
              style: TenantAdminTextStyles.muted(context).copyWith(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name, this.size = 36});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD6A5), Color(0xFFFF9F7A)],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: TenantAdminColors.navy,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Tenant Admin' => TenantAdminColors.info,
      'Manager' => TenantAdminColors.pending,
      'Cashier' => TenantAdminColors.warning,
      _ => const Color(0xFF0891B2),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _UserStatusBadge extends StatelessWidget {
  const _UserStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Active' => TenantAdminColors.success,
      'Invited' => TenantAdminColors.warning,
      'Inactive' => TenantAdminColors.danger,
      _ => TenantAdminColors.offline,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: TenantAdminSpacing.sm),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showUserDetailsDialog(
  BuildContext context,
  _ReferenceUser user, {
  required bool canEdit,
  required bool canDelete,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _UserDetailsDialog(
      user: user,
      canEdit: canEdit,
      canDelete: canDelete,
    ),
  );
}

class _UserDetailsDialog extends StatelessWidget {
  const _UserDetailsDialog({
    required this.user,
    required this.canEdit,
    required this.canDelete,
  });

  final _ReferenceUser user;
  final bool canEdit;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(TenantAdminSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'User Details',
                    style: TenantAdminTextStyles.sectionTitle(context),
                  ),
                  const Spacer(),
                  TenantAdminIconButton(
                    icon: Icons.close,
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Column(
                    children: [
                      _UserAvatar(name: user.name, size: 72),
                      const SizedBox(height: TenantAdminSpacing.md),
                      Text(
                        user.name,
                        style:
                            TenantAdminTextStyles.pageTitle(context).copyWith(
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: TenantAdminSpacing.sm),
                      _RoleBadge(label: user.role),
                      const SizedBox(height: TenantAdminSpacing.sm),
                      Text(
                        user.email,
                        style: TenantAdminTextStyles.muted(context),
                      ),
                    ],
                  ),
                  _UserStatusBadge(status: user.status),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.xl),
              _UserInfoRow(
                icon: Icons.person_outline,
                label: 'Full Name',
                value: user.name,
              ),
              _UserInfoRow(
                icon: Icons.mail_outline,
                label: 'Email Address',
                value: user.email,
              ),
              _UserInfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                value: user.phone,
              ),
              _UserInfoRow(
                icon: Icons.shield_outlined,
                label: 'Role',
                value: user.role,
              ),
              _UserInfoRow(
                icon: Icons.storefront_outlined,
                label: 'Outlet',
                value: user.outlet,
              ),
              _UserInfoRow(
                icon: Icons.radio_button_checked,
                label: 'Status',
                value: user.status,
              ),
              _UserInfoRow(
                icon: Icons.access_time,
                label: 'Last Active',
                value: user.lastActive,
              ),
              _UserInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Joined On',
                value: user.joinedOn,
              ),
              if (canEdit || canDelete) ...[
                const SizedBox(height: TenantAdminSpacing.xl),
                Row(
                  children: [
                    if (canEdit)
                      Expanded(
                        child: TenantAdminSecondaryButton(
                          label: 'Edit User',
                          icon: Icons.edit_outlined,
                          onPressed: () {},
                        ),
                      ),
                    if (canEdit && canDelete)
                      const SizedBox(width: TenantAdminSpacing.md),
                    if (canDelete)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete User'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TenantAdminColors.danger,
                            side: const BorderSide(
                              color: TenantAdminColors.danger,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: TenantAdminSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(TenantAdminRadius.md),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  const _UserInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TenantAdminColors.border)),
      ),
      child: Row(
        children: [
          _IconTile(icon: icon, color: TenantAdminColors.primary),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TenantAdminTextStyles.muted(context)),
          ),
        ],
      ),
    );
  }
}

class _ReferenceUser {
  const _ReferenceUser({
    required this.name,
    required this.email,
    required this.role,
    required this.outlet,
    required this.status,
    required this.lastActive,
    required this.phone,
    required this.joinedOn,
  });

  factory _ReferenceUser.fromJson(Map<String, dynamic> json) {
    final fullName = json['fullName']?.toString() ?? '';
    return _ReferenceUser(
      name: fullName.isEmpty ? 'Unnamed user' : fullName,
      email: json['email']?.toString() ?? '—',
      role: _emptyDash(json['roleName']?.toString()),
      outlet: _emptyDash(json['outletName']?.toString()),
      status: _titleCase(_emptyDash(json['status']?.toString())),
      lastActive: _formatUserDate(json['lastActiveAt']),
      phone: _emptyDash(json['phone']?.toString()),
      joinedOn: _formatUserDate(json['createdAt']),
    );
  }

  final String name;
  final String email;
  final String role;
  final String outlet;
  final String status;
  final String lastActive;
  final String phone;
  final String joinedOn;
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _emptyDash(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? '—' : trimmed;
}

String _titleCase(String value) {
  final normalized = value.trim().replaceAll('_', ' ');
  if (normalized.isEmpty || normalized == '—') {
    return '—';
  }

  return normalized
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String _formatUserDate(Object? value) {
  if (value == null) {
    return '—';
  }

  final date = DateTime.tryParse(value.toString());
  if (date == null) {
    return '—';
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour12 = date.hour == 0
      ? 12
      : date.hour > 12
          ? date.hour - 12
          : date.hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';

  return '${months[date.month - 1]} ${date.day}, ${date.year} '
      '${hour12.toString().padLeft(2, '0')}:$minute $period';
}

const _referenceUsers = [
  _ReferenceUser(
    name: 'John Admin',
    email: 'john.admin@smartpos.com',
    role: 'Tenant Admin',
    outlet: 'Downtown Store',
    status: 'Active',
    lastActive: 'May 15, 2025 10:30 AM',
    phone: '+94 77 123 4567',
    joinedOn: 'Apr 20, 2025 08:15 AM',
  ),
  _ReferenceUser(
    name: 'Sarah Manager',
    email: 'sarah.manager@smartpos.com',
    role: 'Manager',
    outlet: 'City Mall Outlet',
    status: 'Active',
    lastActive: 'May 15, 2025 09:15 AM',
    phone: '+94 77 223 4567',
    joinedOn: 'Apr 24, 2025 09:30 AM',
  ),
  _ReferenceUser(
    name: 'Mike Cashier',
    email: 'mike.cashier@smartpos.com',
    role: 'Cashier',
    outlet: 'Main Branch',
    status: 'Active',
    lastActive: 'May 14, 2025 04:45 PM',
    phone: '+94 77 323 4567',
    joinedOn: 'Apr 26, 2025 11:00 AM',
  ),
  _ReferenceUser(
    name: 'Emma Staff',
    email: 'emma.staff@smartpos.com',
    role: 'Staff',
    outlet: 'Downtown Store',
    status: 'Active',
    lastActive: 'May 14, 2025 02:20 PM',
    phone: '+94 77 423 4567',
    joinedOn: 'Apr 28, 2025 10:45 AM',
  ),
  _ReferenceUser(
    name: 'Tom Staff',
    email: 'tom.staff@smartpos.com',
    role: 'Staff',
    outlet: 'City Mall Outlet',
    status: 'Invited',
    lastActive: '—',
    phone: '+94 77 523 4567',
    joinedOn: 'May 01, 2025 01:20 PM',
  ),
  _ReferenceUser(
    name: 'Lisa Cashier',
    email: 'lisa.cashier@smartpos.com',
    role: 'Cashier',
    outlet: 'Main Branch',
    status: 'Inactive',
    lastActive: 'May 10, 2025 11:05 AM',
    phone: '+94 77 623 4567',
    joinedOn: 'May 02, 2025 08:50 AM',
  ),
  _ReferenceUser(
    name: 'Alex Manager',
    email: 'alex.manager@smartpos.com',
    role: 'Manager',
    outlet: 'Downtown Store',
    status: 'Active',
    lastActive: 'May 13, 2025 08:40 PM',
    phone: '+94 77 723 4567',
    joinedOn: 'May 04, 2025 04:10 PM',
  ),
];

final _tenantAdminProductsProvider =
    FutureProvider.autoDispose<_TenantAdminProductPage>((ref) async {
  final response = await ref.watch(appDioProvider).get<dynamic>(
    '/api/v1/tenant-admin/products',
    queryParameters: const {
      'page': 1,
      'pageSize': 10,
    },
  );

  final body = _asStringKeyMap(response.data);
  return _TenantAdminProductPage.fromJson(_asStringKeyMap(body['data']));
});

Map<String, dynamic> _asStringKeyMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  return <String, dynamic>{};
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

String _asString(Object? value) => value?.toString() ?? '';

class _TenantAdminProductPage {
  const _TenantAdminProductPage({
    required this.summary,
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  factory _TenantAdminProductPage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const [])
        .map((item) => _TenantAdminProductItem.fromJson(_asStringKeyMap(item)))
        .toList();

    return _TenantAdminProductPage(
      summary: _TenantAdminProductSummary.fromJson(
        _asStringKeyMap(json['summary']),
      ),
      items: items,
      page: _asInt(json['page']),
      pageSize: _asInt(json['pageSize']),
      totalCount: _asInt(json['totalCount']),
    );
  }

  final _TenantAdminProductSummary summary;
  final List<_TenantAdminProductItem> items;
  final int page;
  final int pageSize;
  final int totalCount;
}

class _TenantAdminProductSummary {
  const _TenantAdminProductSummary({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.productCategories,
  });

  factory _TenantAdminProductSummary.fromJson(Map<String, dynamic> json) {
    return _TenantAdminProductSummary(
      totalProducts: _asInt(json['totalProducts']),
      activeProducts: _asInt(json['activeProducts']),
      inactiveProducts: _asInt(json['inactiveProducts']),
      productCategories: _asInt(json['productCategories']),
    );
  }

  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int productCategories;
}

class _TenantAdminProductItem {
  const _TenantAdminProductItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.status,
    required this.outletCount,
    this.categoryName,
    this.barcode,
    this.sellingPrice,
  });

  factory _TenantAdminProductItem.fromJson(Map<String, dynamic> json) {
    return _TenantAdminProductItem(
      id: _asString(json['id']),
      name: _asString(json['name']),
      categoryName: _asString(json['categoryName']).isEmpty
          ? null
          : _asString(json['categoryName']),
      sku: _asString(json['sku']),
      barcode: _asString(json['barcode']).isEmpty
          ? null
          : _asString(json['barcode']),
      sellingPrice: _asDouble(json['sellingPrice']),
      status: _asString(json['status']),
      outletCount: _asInt(json['outletCount']),
    );
  }

  final String id;
  final String name;
  final String? categoryName;
  final String sku;
  final String? barcode;
  final double? sellingPrice;
  final String status;
  final int outletCount;
}

class _ProductListScreen extends ConsumerWidget {
  const _ProductListScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);

    return accessState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Products',
        subtitle: 'Manage items, pricing and availability across outlets.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Products',
        subtitle: 'Manage items, pricing and availability across outlets.',
        child: TenantAdminErrorState(
          title: 'Unable to load product access',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(tenantAdminAccessCheckerProvider),
        ),
      ),
      data: (access) {
        if (!access.canAny(_productViewPermissions)) {
          return const TenantAdminPageScaffold(
            title: 'No access to Products',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view products.',
              icon: Icons.inventory_2_outlined,
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 780;
            final canCreate = access.canAny(_productCreatePermissions);
            final productsState = ref.watch(_tenantAdminProductsProvider);

            return TenantAdminPageScaffold(
              title: 'Products',
              subtitle:
                  'Manage items, pricing and availability across outlets.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductToolbar(canCreate: canCreate, compact: isCompact),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  _ProductSummaryCards(
                    compact: isCompact,
                    summary: productsState.valueOrNull?.summary,
                  ),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  _ProductsTableCardLive(
                    access: access,
                    productsState: productsState,
                    onRetry: () => ref.invalidate(_tenantAdminProductsProvider),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductToolbar extends StatelessWidget {
  const _ProductToolbar({
    required this.canCreate,
    required this.compact,
  });

  final bool canCreate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const search = _SearchField(hintText: 'Search products by name or SKU');
    const filters = TenantAdminSecondaryButton(
      label: 'Filters',
      icon: Icons.tune,
      onPressed: null,
    );
    final addButton = TenantAdminPrimaryButton(
      label: 'Add product',
      icon: Icons.add,
      onPressed:
          canCreate ? () => context.go('/tenant-admin/products/add') : null,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: TenantAdminSpacing.md),
          Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: [
              filters,
              if (canCreate) addButton,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        const Expanded(child: search),
        const SizedBox(width: TenantAdminSpacing.md),
        filters,
        if (canCreate) ...[
          const SizedBox(width: TenantAdminSpacing.md),
          addButton,
        ],
      ],
    );
  }
}

class _ProductSummaryCards extends StatelessWidget {
  const _ProductSummaryCards({
    required this.compact,
    required this.summary,
  });

  final bool compact;
  final _TenantAdminProductSummary? summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricData(
        title: 'Total Products',
        value: '${summary?.totalProducts ?? 0}',
        subtitle: 'Products in catalogue',
        icon: Icons.inventory_2_outlined,
        color: TenantAdminColors.primary,
      ),
      _MetricData(
        title: 'Active Products',
        value: '${summary?.activeProducts ?? 0}',
        subtitle: 'Available for sale',
        icon: Icons.check_circle_outline,
        color: TenantAdminColors.success,
      ),
      _MetricData(
        title: 'Inactive Products',
        value: '${summary?.inactiveProducts ?? 0}',
        subtitle: 'Hidden from tills',
        icon: Icons.pause_circle_outline,
        color: TenantAdminColors.offline,
      ),
      _MetricData(
        title: 'Product Categories',
        value: '${summary?.productCategories ?? 0}',
        subtitle: 'Categories in use',
        icon: Icons.category_outlined,
        color: TenantAdminColors.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact
            ? 1
            : constraints.maxWidth >= 960
                ? 4
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: TenantAdminSpacing.lg,
            mainAxisSpacing: TenantAdminSpacing.lg,
            childAspectRatio: columns == 1
                ? 4.2
                : columns == 2
                    ? 2.2
                    : 1.85,
          ),
          itemBuilder: (context, index) => _MetricCard(data: cards[index]),
        );
      },
    );
  }
}

class _ProductsTableCardLive extends StatelessWidget {
  const _ProductsTableCardLive({
    required this.access,
    required this.productsState,
    required this.onRetry,
  });

  final TenantAdminAccessChecker access;
  final AsyncValue<_TenantAdminProductPage> productsState;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return productsState.when(
      loading: () => Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        decoration: _cardDecoration(),
        child: const TenantAdminLoadingSkeleton(rowCount: 6),
      ),
      error: (error, stackTrace) => Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        decoration: _cardDecoration(),
        child: TenantAdminErrorState(
          title: 'Unable to load products',
          message: error is DioException
              ? messageFromDioException(
                  error,
                  fallback: 'Please check the API server and try again.',
                )
              : 'Please check the API server and try again.',
          onRetry: onRetry,
        ),
      ),
      data: (page) => _ProductsDataTableCard(access: access, page: page),
    );
  }
}

class _ProductsDataTableCard extends StatelessWidget {
  const _ProductsDataTableCard({
    required this.access,
    required this.page,
  });

  final TenantAdminAccessChecker access;
  final _TenantAdminProductPage page;

  @override
  Widget build(BuildContext context) {
    final canView = access.canAny(_productDetailPermissions);
    final canEdit = access.canAny(_productEditPermissions);
    final canStatus = access.canAny(_productStatusPermissions);
    final canDelete = access.canAny(_productDeletePermissions);
    final showActions = canView || canEdit || canStatus || canDelete;
    final start =
        page.totalCount == 0 ? 0 : ((page.page - 1) * page.pageSize) + 1;
    final calculatedEnd = page.page * page.pageSize;
    final end =
        calculatedEnd > page.totalCount ? page.totalCount : calculatedEnd;

    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1120),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  TenantAdminColors.background,
                ),
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Checkbox(value: false, onChanged: null)),
                  DataColumn(label: Text('Product Name')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('SKU')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Outlets')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: page.items
                    .map(
                      (product) => DataRow(
                        cells: [
                          const DataCell(
                            Checkbox(value: false, onChanged: null),
                          ),
                          DataCell(
                            _ProductNameCell(
                              name: product.name,
                              subtitle: product.barcode == null
                                  ? 'SKU ${product.sku}'
                                  : 'SKU ${product.sku} • ${product.barcode}',
                              icon: Icons.inventory_2_outlined,
                            ),
                          ),
                          DataCell(
                            access.canAny(_productCategoryViewPermissions)
                                ? _CategoryPill(
                                    label:
                                        product.categoryName ?? 'Uncategorised',
                                  )
                                : const _EmptyTableText('Hidden'),
                          ),
                          DataCell(Text(product.sku)),
                          DataCell(
                            _EmptyTableText(_formatPrice(product.sellingPrice)),
                          ),
                          DataCell(
                            _StatusPill(label: _titleCase(product.status)),
                          ),
                          DataCell(
                            _EmptyTableText(
                              '${product.outletCount} ${product.outletCount == 1 ? 'outlet' : 'outlets'}',
                            ),
                          ),
                          DataCell(
                            showActions
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (canView)
                                        _ActionButton(
                                          label: 'View',
                                          icon: Icons.visibility_outlined,
                                          onPressed: () => context.go(
                                            '/tenant-admin/products/${product.id}',
                                          ),
                                        ),
                                      if (canEdit) ...[
                                        const SizedBox(
                                          width: TenantAdminSpacing.sm,
                                        ),
                                        TenantAdminIconButton(
                                          icon: Icons.edit_outlined,
                                          tooltip: 'Edit',
                                          onPressed: () => context.go(
                                            '/tenant-admin/products/${product.id}/edit',
                                          ),
                                        ),
                                      ],
                                      if (canStatus || canDelete) ...[
                                        const SizedBox(
                                          width: TenantAdminSpacing.sm,
                                        ),
                                        const TenantAdminIconButton(
                                          icon: Icons.more_vert,
                                          tooltip: 'More',
                                          onPressed: null,
                                        ),
                                      ],
                                    ],
                                  )
                                : const _EmptyTableText('Hidden'),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          if (page.items.isEmpty) ...[
            const Divider(height: 1, color: TenantAdminColors.border),
            const Padding(
              padding: EdgeInsets.all(TenantAdminSpacing.xl),
              child: TenantAdminEmptyState(
                title: 'No products available',
                message: 'Create a product to see it in this list.',
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
          const Divider(height: 1, color: TenantAdminColors.border),
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Showing $start to $end of ${page.totalCount} products',
                  style: TenantAdminTextStyles.muted(context),
                ),
                const Spacer(),
                const _PaginationButton(
                  icon: Icons.chevron_left,
                  enabled: false,
                ),
                const SizedBox(width: TenantAdminSpacing.sm),
                _PageNumberButton(label: '${page.page}', selected: true),
                const SizedBox(width: TenantAdminSpacing.sm),
                _PaginationButton(
                  icon: Icons.chevron_right,
                  enabled: page.totalCount > end,
                ),
                const SizedBox(width: TenantAdminSpacing.lg),
                const _RowsPerPageButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPrice(double? price) {
    return price == null ? '-' : 'LKR ${price.toStringAsFixed(2)}';
  }

  static String _titleCase(String value) {
    if (value.isEmpty) {
      return '-';
    }

    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}

class _ProductsTableCard extends StatelessWidget {
  const _ProductsTableCard({required this.access});

  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context) {
    final canView = access.canAny(_productDetailPermissions);
    final canEdit = access.canAny(_productEditPermissions);
    final canStatus = access.canAny(_productStatusPermissions);
    final canDelete = access.canAny(_productDeletePermissions);
    final showActions = canView || canEdit || canStatus || canDelete;

    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1120),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  TenantAdminColors.background,
                ),
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Checkbox(value: false, onChanged: null)),
                  DataColumn(label: Text('Product Name')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('SKU')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Outlets')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: [
                  DataRow(
                    cells: [
                      const DataCell(Checkbox(value: false, onChanged: null)),
                      const DataCell(
                        _ProductNameCell(
                          name: 'No products yet',
                          subtitle: 'Product provider is not connected yet',
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                      DataCell(
                        access.canAny(_productCategoryViewPermissions)
                            ? const _CategoryPill(label: 'Empty')
                            : const _EmptyTableText('Hidden'),
                      ),
                      const DataCell(_EmptyTableText('—')),
                      const DataCell(_EmptyTableText('—')),
                      const DataCell(_StatusPill(label: 'Empty')),
                      const DataCell(_EmptyTableText('0 outlets')),
                      DataCell(
                        showActions
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (canView)
                                    const _ActionButton(
                                      label: 'View',
                                      icon: Icons.visibility_outlined,
                                      onPressed: null,
                                    ),
                                  if (canEdit) ...[
                                    const SizedBox(
                                      width: TenantAdminSpacing.sm,
                                    ),
                                    const TenantAdminIconButton(
                                      icon: Icons.edit_outlined,
                                      tooltip: 'Edit',
                                      onPressed: null,
                                    ),
                                  ],
                                  if (canStatus || canDelete) ...[
                                    const SizedBox(
                                      width: TenantAdminSpacing.sm,
                                    ),
                                    const TenantAdminIconButton(
                                      icon: Icons.more_vert,
                                      tooltip: 'More',
                                      onPressed: null,
                                    ),
                                  ],
                                ],
                              )
                            : const _EmptyTableText('Hidden'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          const Padding(
            padding: EdgeInsets.all(TenantAdminSpacing.xl),
            child: TenantAdminEmptyState(
              title: 'No products available',
              message:
                  'Product list API/provider is not available in this frontend yet.',
              icon: Icons.inventory_2_outlined,
            ),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Showing 0 to 0 of 0 products',
                  style: TenantAdminTextStyles.muted(context),
                ),
                const Spacer(),
                const _PaginationButton(
                  icon: Icons.chevron_left,
                  enabled: false,
                ),
                const SizedBox(width: TenantAdminSpacing.sm),
                const _PageNumberButton(label: '1', selected: true),
                const SizedBox(width: TenantAdminSpacing.sm),
                const _PaginationButton(
                  icon: Icons.chevron_right,
                  enabled: false,
                ),
                const SizedBox(width: TenantAdminSpacing.lg),
                const _RowsPerPageButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductNameCell extends StatelessWidget {
  const _ProductNameCell({
    required this.name,
    required this.subtitle,
    required this.icon,
  });

  final String name;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconTile(icon: icon, color: TenantAdminColors.primary),
        const SizedBox(width: TenantAdminSpacing.md),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              subtitle,
              style: TenantAdminTextStyles.muted(context).copyWith(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TenantAdminColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: TenantAdminColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AddProductScreen extends ConsumerStatefulWidget {
  const _AddProductScreen();

  @override
  ConsumerState<_AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<_AddProductScreen> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _unitController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _taxController = TextEditingController();
  final _openingStockController = TextEditingController();
  final _lowStockController = TextEditingController();
  final _selectedOutlets = <String>{};

  var _stepIndex = 0;
  var _trackStock = false;
  var _isSavingProduct = false;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _unitController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _taxController.dispose();
    _openingStockController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);
    final contextState = ref.watch(tenantAdminContextProvider);

    return accessState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Add product',
        subtitle: 'Enter the main details for a new product.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Add product',
        subtitle: 'Enter the main details for a new product.',
        child: TenantAdminErrorState(
          title: 'Unable to load product access',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(tenantAdminAccessCheckerProvider),
        ),
      ),
      data: (access) {
        if (!access.canAny(_productCreatePermissions)) {
          return const TenantAdminPageScaffold(
            title: 'No access',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to add products.',
              icon: Icons.inventory_2_outlined,
            ),
          );
        }

        return TenantAdminPageScaffold(
          title: 'Add product',
          subtitle: 'Enter the main details for a new product.',
          child: contextState.when(
            loading: () => const TenantAdminLoadingSkeleton(rowCount: 8),
            error: (error, stackTrace) => TenantAdminErrorState(
              title: 'Unable to load tenant context',
              message: 'Please try again.',
              onRetry: () => ref.invalidate(tenantAdminContextProvider),
            ),
            data: (tenantContext) => _AddProductWizard(
              stepIndex: _stepIndex,
              access: access,
              tenantContext: tenantContext,
              nameController: _nameController,
              skuController: _skuController,
              categoryController: _categoryController,
              brandController: _brandController,
              unitController: _unitController,
              barcodeController: _barcodeController,
              descriptionController: _descriptionController,
              priceController: _priceController,
              taxController: _taxController,
              openingStockController: _openingStockController,
              lowStockController: _lowStockController,
              selectedOutlets: _selectedOutlets,
              trackStock: _trackStock,
              isSaving: _isSavingProduct,
              onTrackStockChanged: (value) {
                setState(() => _trackStock = value);
              },
              onOutletChanged: _toggleOutlet,
              onBack: _back,
              onContinue: _continue,
              onSaveDraft: _showDraftMessage,
            ),
          ),
        );
      },
    );
  }

  void _back() {
    if (_stepIndex == 0) {
      context.go('/tenant-admin/products');
      return;
    }

    setState(() => _stepIndex--);
  }

  void _continue() {
    if (_stepIndex < 3) {
      setState(() => _stepIndex++);
      return;
    }

    _createProduct();
  }

  void _toggleOutlet(String outletId, bool selected) {
    setState(() {
      if (selected) {
        _selectedOutlets.add(outletId);
      } else {
        _selectedOutlets.remove(outletId);
      }
    });
  }

  void _showDraftMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft UI is ready. Product API/provider is pending.'),
      ),
    );
  }

  Future<void> _createProduct() async {
    if (_isSavingProduct) {
      return;
    }

    final name = _nameController.text.trim();
    final sku = _skuController.text.trim();
    if (name.isEmpty || sku.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product name and SKU are required.')),
      );
      if (_stepIndex != 0) {
        setState(() => _stepIndex = 0);
      }
      return;
    }

    final sellingPrice = _parseDecimal(_priceController.text);
    if (_priceController.text.trim().isNotEmpty && sellingPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selling price must be a valid number.')),
      );
      if (_stepIndex != 1) {
        setState(() => _stepIndex = 1);
      }
      return;
    }

    setState(() => _isSavingProduct = true);

    try {
      await ref.read(appDioProvider).post<dynamic>(
        '/api/v1/tenant-admin/products',
        data: {
          'name': name,
          'sku': sku,
          if (_categoryController.text.trim().isNotEmpty)
            'categoryName': _categoryController.text.trim(),
          if (_brandController.text.trim().isNotEmpty)
            'brandName': _brandController.text.trim(),
          if (_unitController.text.trim().isNotEmpty)
            'unitType': _unitController.text.trim(),
          if (_barcodeController.text.trim().isNotEmpty)
            'barcode': _barcodeController.text.trim(),
          if (_descriptionController.text.trim().isNotEmpty)
            'description': _descriptionController.text.trim(),
          if (sellingPrice != null) 'sellingPrice': sellingPrice,
          'trackStock': _trackStock,
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product created successfully.')),
      );
      ref.invalidate(_tenantAdminProductsProvider);
      context.go('/tenant-admin/products');
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            messageFromDioException(
              error,
              fallback: 'Product create failed. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingProduct = false);
      }
    }
  }
}

double? _parseDecimal(String value) {
  if (value.trim().isEmpty) {
    return null;
  }

  return double.tryParse(value.trim());
}

class _AddProductWizard extends StatelessWidget {
  const _AddProductWizard({
    required this.stepIndex,
    required this.access,
    required this.tenantContext,
    required this.nameController,
    required this.skuController,
    required this.categoryController,
    required this.brandController,
    required this.unitController,
    required this.barcodeController,
    required this.descriptionController,
    required this.priceController,
    required this.taxController,
    required this.openingStockController,
    required this.lowStockController,
    required this.selectedOutlets,
    required this.trackStock,
    required this.isSaving,
    required this.onTrackStockChanged,
    required this.onOutletChanged,
    required this.onBack,
    required this.onContinue,
    required this.onSaveDraft,
  });

  final int stepIndex;
  final TenantAdminAccessChecker access;
  final TenantAdminContext tenantContext;
  final TextEditingController nameController;
  final TextEditingController skuController;
  final TextEditingController categoryController;
  final TextEditingController brandController;
  final TextEditingController unitController;
  final TextEditingController barcodeController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController taxController;
  final TextEditingController openingStockController;
  final TextEditingController lowStockController;
  final Set<String> selectedOutlets;
  final bool trackStock;
  final bool isSaving;
  final ValueChanged<bool> onTrackStockChanged;
  final void Function(String outletId, bool selected) onOutletChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSaveDraft;

  @override
  Widget build(BuildContext context) {
    final isReview = stepIndex == 3;
    final canCreate = access.canAny(_productCreatePermissions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProductStepper(currentStep: stepIndex),
        const SizedBox(height: TenantAdminSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 920;
            final form = Container(
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
              decoration: _cardDecoration(),
              child: _ProductWizardBody(
                stepIndex: stepIndex,
                access: access,
                tenantContext: tenantContext,
                nameController: nameController,
                skuController: skuController,
                categoryController: categoryController,
                brandController: brandController,
                unitController: unitController,
                barcodeController: barcodeController,
                descriptionController: descriptionController,
                priceController: priceController,
                taxController: taxController,
                openingStockController: openingStockController,
                lowStockController: lowStockController,
                selectedOutlets: selectedOutlets,
                trackStock: trackStock,
                onTrackStockChanged: onTrackStockChanged,
                onOutletChanged: onOutletChanged,
              ),
            );

            if (compact) {
              return Column(
                children: [
                  form,
                  const SizedBox(height: TenantAdminSpacing.lg),
                  const _ProductHelperPanel(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: form),
                const SizedBox(width: TenantAdminSpacing.xl),
                const Expanded(flex: 3, child: _ProductHelperPanel()),
              ],
            );
          },
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        _WizardFooter(
          stepIndex: stepIndex,
          onBack: onBack,
          onSaveDraft: onSaveDraft,
          onContinue: isReview && (!canCreate || isSaving) ? null : onContinue,
          continueLabel: isReview
              ? isSaving
                  ? 'Creating...'
                  : 'Create product'
              : 'Continue',
        ),
      ],
    );
  }
}

class _ProductStepper extends StatelessWidget {
  const _ProductStepper({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Basic details',
      'Price & VAT',
      'Stock details',
      'Review',
    ];

    return Container(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TenantAdminColors.border)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Expanded(
              child: _StepperItem(
                number: index + 1,
                label: steps[index],
                selected: index == currentStep,
                done: index < currentStep,
              ),
            ),
            if (index != steps.length - 1)
              Container(
                width: 34,
                height: 2,
                color: index < currentStep
                    ? TenantAdminColors.primary
                    : TenantAdminColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProductWizardBody extends StatelessWidget {
  const _ProductWizardBody({
    required this.stepIndex,
    required this.access,
    required this.tenantContext,
    required this.nameController,
    required this.skuController,
    required this.categoryController,
    required this.brandController,
    required this.unitController,
    required this.barcodeController,
    required this.descriptionController,
    required this.priceController,
    required this.taxController,
    required this.openingStockController,
    required this.lowStockController,
    required this.selectedOutlets,
    required this.trackStock,
    required this.onTrackStockChanged,
    required this.onOutletChanged,
  });

  final int stepIndex;
  final TenantAdminAccessChecker access;
  final TenantAdminContext tenantContext;
  final TextEditingController nameController;
  final TextEditingController skuController;
  final TextEditingController categoryController;
  final TextEditingController brandController;
  final TextEditingController unitController;
  final TextEditingController barcodeController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController taxController;
  final TextEditingController openingStockController;
  final TextEditingController lowStockController;
  final Set<String> selectedOutlets;
  final bool trackStock;
  final ValueChanged<bool> onTrackStockChanged;
  final void Function(String outletId, bool selected) onOutletChanged;

  @override
  Widget build(BuildContext context) {
    switch (stepIndex) {
      case 1:
        return _ProductPriceVatStep(
          access: access,
          priceController: priceController,
          taxController: taxController,
        );
      case 2:
        return _ProductStockStep(
          access: access,
          tenantContext: tenantContext,
          openingStockController: openingStockController,
          lowStockController: lowStockController,
          selectedOutlets: selectedOutlets,
          trackStock: trackStock,
          onTrackStockChanged: onTrackStockChanged,
          onOutletChanged: onOutletChanged,
        );
      case 3:
        return _ProductReviewStep(
          nameController: nameController,
          skuController: skuController,
          categoryController: categoryController,
          brandController: brandController,
          unitController: unitController,
          barcodeController: barcodeController,
          descriptionController: descriptionController,
          priceController: priceController,
          taxController: taxController,
          openingStockController: openingStockController,
          lowStockController: lowStockController,
          selectedOutlets: selectedOutlets,
          tenantContext: tenantContext,
          trackStock: trackStock,
        );
      default:
        return _ProductBasicDetailsStep(
          access: access,
          nameController: nameController,
          skuController: skuController,
          categoryController: categoryController,
          brandController: brandController,
          unitController: unitController,
          barcodeController: barcodeController,
          descriptionController: descriptionController,
        );
    }
  }
}

class _ProductBasicDetailsStep extends StatelessWidget {
  const _ProductBasicDetailsStep({
    required this.access,
    required this.nameController,
    required this.skuController,
    required this.categoryController,
    required this.brandController,
    required this.unitController,
    required this.barcodeController,
    required this.descriptionController,
  });

  final TenantAdminAccessChecker access;
  final TextEditingController nameController;
  final TextEditingController skuController;
  final TextEditingController categoryController;
  final TextEditingController brandController;
  final TextEditingController unitController;
  final TextEditingController barcodeController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    final canViewCategory = access.canAny(_productCategoryViewPermissions);
    final canManageImage = access.canAny(_productImagePermissions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic details',
          style: TenantAdminTextStyles.sectionTitle(context),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 720;
            final fields = [
              _FormInput(
                label: 'Product name',
                hint: 'Enter product name',
                icon: Icons.inventory_2_outlined,
                controller: nameController,
              ),
              _FormInput(
                label: 'Product code / SKU',
                hint: 'Enter SKU',
                icon: Icons.qr_code_2_outlined,
                controller: skuController,
              ),
              _FormInput(
                label: 'Category',
                hint: canViewCategory
                    ? 'Enter or choose category'
                    : 'Category permission unavailable',
                icon: Icons.category_outlined,
                controller: categoryController,
              ),
              _FormInput(
                label: 'Brand (optional)',
                hint: 'Enter brand',
                icon: Icons.sell_outlined,
                controller: brandController,
              ),
              _FormInput(
                label: 'Unit type',
                hint: 'E.g. Each, Kg, Litre',
                icon: Icons.straighten_outlined,
                controller: unitController,
              ),
              _FormInput(
                label: 'Barcode (optional)',
                hint: 'Enter barcode',
                icon: Icons.barcode_reader,
                controller: barcodeController,
              ),
            ];

            if (!twoColumns) {
              return Column(
                children: [
                  for (final field in fields) ...[
                    field,
                    const SizedBox(height: TenantAdminSpacing.lg),
                  ],
                  _ProductImagePicker(enabled: canManageImage),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  _FormInput(
                    label: 'Short description (optional)',
                    hint: 'Add a short product description',
                    icon: Icons.notes_outlined,
                    controller: descriptionController,
                  ),
                ],
              );
            }

            return Column(
              children: [
                for (var index = 0; index < fields.length; index += 2) ...[
                  Row(
                    children: [
                      Expanded(child: fields[index]),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(child: fields[index + 1]),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FormInput(
                        label: 'Short description (optional)',
                        hint: 'Add a short product description',
                        icon: Icons.notes_outlined,
                        controller: descriptionController,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.lg),
                    Expanded(
                        child: _ProductImagePicker(enabled: canManageImage)),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProductImagePicker extends StatelessWidget {
  const _ProductImagePicker({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: TenantAdminColors.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          _IconTile(
            icon: Icons.image_outlined,
            color:
                enabled ? TenantAdminColors.primary : TenantAdminColors.offline,
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product image (optional)',
                  style: TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  enabled
                      ? 'Upload UI is ready for existing image provider.'
                      : 'Image manage permission/provider unavailable.',
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPriceVatStep extends StatelessWidget {
  const _ProductPriceVatStep({
    required this.access,
    required this.priceController,
    required this.taxController,
  });

  final TenantAdminAccessChecker access;
  final TextEditingController priceController;
  final TextEditingController taxController;

  @override
  Widget build(BuildContext context) {
    final canManagePrice = access.canAny(_productPricePermissions);
    final canManageTax = access.canAny(_productTaxPermissions);

    if (!canManagePrice && !canManageTax) {
      return const TenantAdminEmptyState(
        title: 'Price & VAT setup unavailable',
        message:
            'No existing price or VAT permission/provider is available for this frontend yet.',
        icon: Icons.payments_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price & VAT', style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(height: TenantAdminSpacing.lg),
        if (canManagePrice) ...[
          _FormInput(
            label: 'Selling price',
            hint: 'Enter selling price',
            icon: Icons.payments_outlined,
            controller: priceController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
        ],
        if (canManageTax)
          _FormInput(
            label: 'VAT / Tax',
            hint: 'Tax provider unavailable',
            icon: Icons.receipt_long_outlined,
            controller: taxController,
          )
        else
          const TenantAdminEmptyState(
            title: 'VAT provider unavailable',
            message:
                'Existing tax data/provider was not found, so VAT selection is hidden.',
            icon: Icons.receipt_long_outlined,
          ),
      ],
    );
  }
}

class _ProductStockStep extends StatelessWidget {
  const _ProductStockStep({
    required this.access,
    required this.tenantContext,
    required this.openingStockController,
    required this.lowStockController,
    required this.selectedOutlets,
    required this.trackStock,
    required this.onTrackStockChanged,
    required this.onOutletChanged,
  });

  final TenantAdminAccessChecker access;
  final TenantAdminContext tenantContext;
  final TextEditingController openingStockController;
  final TextEditingController lowStockController;
  final Set<String> selectedOutlets;
  final bool trackStock;
  final ValueChanged<bool> onTrackStockChanged;
  final void Function(String outletId, bool selected) onOutletChanged;

  @override
  Widget build(BuildContext context) {
    final canManageStock = access.canAny(_productStockPermissions);
    final canAssignOutlets = access.canAny(_productOutletAssignPermissions);

    if (!canManageStock && !canAssignOutlets) {
      return const TenantAdminEmptyState(
        title: 'Stock setup unavailable',
        message:
            'No existing stock or outlet assignment permission/provider is available for products yet.',
        icon: Icons.warehouse_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock details',
          style: TenantAdminTextStyles.sectionTitle(context),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        if (canManageStock) ...[
          SwitchListTile(
            value: trackStock,
            onChanged: onTrackStockChanged,
            title: const Text('Track stock for this product'),
            subtitle: const Text('Enable opening stock and low stock alerts.'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _FormInput(
                  label: 'Opening stock',
                  hint: '0',
                  icon: Icons.inventory_outlined,
                  controller: openingStockController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.lg),
              Expanded(
                child: _FormInput(
                  label: 'Low stock threshold',
                  hint: '0',
                  icon: Icons.warning_amber_outlined,
                  controller: lowStockController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
        ],
        if (canAssignOutlets && tenantContext.outletScope.isNotEmpty)
          for (final outlet in tenantContext.outletScope) ...[
            CheckboxListTile(
              value: selectedOutlets.contains(outlet.outletId),
              onChanged: (value) =>
                  onOutletChanged(outlet.outletId, value ?? false),
              title: Text(
                outlet.outletName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(outlet.outletId),
              secondary: const _IconTile(
                icon: Icons.storefront_outlined,
                color: TenantAdminColors.primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                side: const BorderSide(color: TenantAdminColors.border),
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
          ]
        else
          const TenantAdminEmptyState(
            title: 'No outlet allocation data',
            message:
                'Existing outlet assignment data/provider is unavailable for products.',
            icon: Icons.storefront_outlined,
          ),
      ],
    );
  }
}

class _ProductReviewStep extends StatelessWidget {
  const _ProductReviewStep({
    required this.nameController,
    required this.skuController,
    required this.categoryController,
    required this.brandController,
    required this.unitController,
    required this.barcodeController,
    required this.descriptionController,
    required this.priceController,
    required this.taxController,
    required this.openingStockController,
    required this.lowStockController,
    required this.selectedOutlets,
    required this.tenantContext,
    required this.trackStock,
  });

  final TextEditingController nameController;
  final TextEditingController skuController;
  final TextEditingController categoryController;
  final TextEditingController brandController;
  final TextEditingController unitController;
  final TextEditingController barcodeController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController taxController;
  final TextEditingController openingStockController;
  final TextEditingController lowStockController;
  final Set<String> selectedOutlets;
  final TenantAdminContext tenantContext;
  final bool trackStock;

  @override
  Widget build(BuildContext context) {
    final outletNames = tenantContext.outletScope
        .where((outlet) => selectedOutlets.contains(outlet.outletId))
        .map((outlet) => outlet.outletName)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review', style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(height: TenantAdminSpacing.lg),
        _ReviewRow(
            label: 'Product name', value: _fallback(nameController.text)),
        _ReviewRow(label: 'SKU', value: _fallback(skuController.text)),
        _ReviewRow(
            label: 'Category', value: _fallback(categoryController.text)),
        _ReviewRow(label: 'Brand', value: _fallback(brandController.text)),
        _ReviewRow(label: 'Unit type', value: _fallback(unitController.text)),
        _ReviewRow(label: 'Barcode', value: _fallback(barcodeController.text)),
        _ReviewRow(
          label: 'Description',
          value: _fallback(descriptionController.text),
        ),
        _ReviewRow(
            label: 'Selling price', value: _fallback(priceController.text)),
        _ReviewRow(label: 'VAT / Tax', value: _fallback(taxController.text)),
        _ReviewRow(label: 'Track stock', value: trackStock ? 'Yes' : 'No'),
        _ReviewRow(
          label: 'Opening stock',
          value: _fallback(openingStockController.text),
        ),
        _ReviewRow(
          label: 'Low stock threshold',
          value: _fallback(lowStockController.text),
        ),
        _ReviewRow(
          label: 'Outlet allocation',
          value: outletNames.isEmpty ? 'Not selected' : outletNames,
        ),
      ],
    );
  }
}

class _ProductHelperPanel extends StatelessWidget {
  const _ProductHelperPanel();

  @override
  Widget build(BuildContext context) {
    const items = [
      _HelperItem(
        icon: Icons.inventory_2_outlined,
        title: 'Choose a clear product name',
      ),
      _HelperItem(
        icon: Icons.category_outlined,
        title: 'Add a category and unit type',
      ),
      _HelperItem(
        icon: Icons.payments_outlined,
        title: 'You can set price and stock in the next steps',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TenantAdminColors.primary.withValues(alpha: 0.08),
            TenantAdminColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before you continue',
            style: TenantAdminTextStyles.sectionTitle(context).copyWith(
              color: TenantAdminColors.primary,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconTile(icon: item.icon, color: TenantAdminColors.primary),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (item != items.last)
              const SizedBox(height: TenantAdminSpacing.xl),
          ],
        ],
      ),
    );
  }
}

class _AddStaffScreen extends ConsumerStatefulWidget {
  const _AddStaffScreen();

  @override
  ConsumerState<_AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends ConsumerState<_AddStaffScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _staffCodeController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _notesController = TextEditingController();
  final _selectedOutlets = <String>{};

  var _stepIndex = 0;
  var _permissionOverride = false;
  var _sendInvite = true;
  var _isSaving = false;
  String? _selectedRole;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _staffCodeController.dispose();
    _jobTitleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);
    final contextState = ref.watch(tenantAdminContextProvider);

    return accessState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Add New User',
        subtitle:
            'Create a new user and assign access, outlets, and permissions.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Add New User',
        subtitle:
            'Create a new user and assign access, outlets, and permissions.',
        child: TenantAdminErrorState(
          title: 'Unable to load user access',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(tenantAdminAccessCheckerProvider),
        ),
      ),
      data: (access) {
        if (!access.canAny(_staffCreatePermissions)) {
          return const TenantAdminPageScaffold(
            title: 'No access',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to add users.',
            ),
          );
        }

        return TenantAdminPageScaffold(
          title: 'Add New User',
          subtitle:
              'Create a new user and assign access, outlets, and permissions.',
          child: contextState.when(
            loading: () => const TenantAdminLoadingSkeleton(rowCount: 8),
            error: (error, stackTrace) => TenantAdminErrorState(
              title: 'Unable to load tenant context',
              message: 'Please try again.',
              onRetry: () => ref.invalidate(tenantAdminContextProvider),
            ),
            data: (tenantContext) => _AddUserReferenceForm(
              selectedRole: _selectedRole,
              selectedOutlets: _selectedOutlets,
              tenantContext: tenantContext,
              access: access,
              fullNameController: _firstNameController,
              emailController: _emailController,
              phoneController: _mobileController,
              permissionOverride: _permissionOverride,
              sendInvite: _sendInvite,
              isSaving: _isSaving,
              onRoleSelected: (role) => setState(() {
                _selectedRole = role;
                _permissionOverride = role != null && _permissionOverride;
              }),
              onOutletChanged: _toggleOutlet,
              onPermissionOverrideChanged: (value) =>
                  setState(() => _permissionOverride = value),
              onSendInviteChanged: (value) =>
                  setState(() => _sendInvite = value),
              onCancel: () => context.go('/tenant-admin/staff'),
              onSave: () => _saveUser(tenantContext),
            ),
          ),
        );
      },
    );
  }

  void _back() {
    if (_stepIndex == 0) {
      context.go('/tenant-admin/staff');
      return;
    }

    setState(() => _stepIndex--);
  }

  void _continue() {
    if (_stepIndex < 3) {
      setState(() => _stepIndex++);
      return;
    }

    final contextState = ref.read(tenantAdminContextProvider);
    final tenantContext = contextState.valueOrNull;
    if (tenantContext != null) {
      _saveUser(tenantContext);
    }
  }

  void _toggleOutlet(String outletId, bool selected) {
    setState(() {
      if (selected) {
        _selectedOutlets.add(outletId);
      } else {
        _selectedOutlets.remove(outletId);
      }
    });
  }

  void _showDraftMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft UI is ready. Staff API is pending.')),
    );
  }

  Future<void> _saveUser(TenantAdminContext tenantContext) async {
    if (_isSaving) {
      return;
    }

    final selectedRole = _selectedRole;
    TenantAdminRoleScope? role;
    if (selectedRole != null) {
      for (final item in tenantContext.roles) {
        if (item.roleName == selectedRole) {
          role = item;
          break;
        }
      }
    }

    if (_firstNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        role == null ||
        role.roleId.isEmpty ||
        _selectedOutlets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full name, email, role and outlet are required.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(appDioProvider).post<dynamic>(
        '/api/v1/tenant-admin/users',
        data: {
          'fullName': _firstNameController.text.trim(),
          'email': _emailController.text.trim(),
          if (_mobileController.text.trim().isNotEmpty)
            'phone': _mobileController.text.trim(),
          'roleId': role.roleId,
          'outletIds': _selectedOutlets.toList(growable: false),
          'sendInviteEmail': _sendInvite,
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User invited successfully.')),
      );
      context.go('/tenant-admin/staff');
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            messageFromDioException(
              error,
              fallback: 'User invite failed. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showInviteMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite UI is ready. Staff API is pending.'),
      ),
    );
  }
}

class _AddUserReferenceForm extends StatelessWidget {
  const _AddUserReferenceForm({
    required this.selectedRole,
    required this.selectedOutlets,
    required this.tenantContext,
    required this.access,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.permissionOverride,
    required this.sendInvite,
    required this.isSaving,
    required this.onRoleSelected,
    required this.onOutletChanged,
    required this.onPermissionOverrideChanged,
    required this.onSendInviteChanged,
    required this.onCancel,
    required this.onSave,
  });

  final String? selectedRole;
  final Set<String> selectedOutlets;
  final TenantAdminContext tenantContext;
  final TenantAdminAccessChecker access;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final bool permissionOverride;
  final bool sendInvite;
  final bool isSaving;
  final ValueChanged<String?> onRoleSelected;
  final void Function(String outletId, bool selected) onOutletChanged;
  final ValueChanged<bool> onPermissionOverrideChanged;
  final ValueChanged<bool> onSendInviteChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final canOverride = access.canAny(_staffPermissionOverridePermissions);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showPanel = canOverride && permissionOverride;
        final wide = constraints.maxWidth >= 980;
        final form = _AddUserMainCard(
          selectedRole: selectedRole,
          selectedOutlets: selectedOutlets,
          tenantContext: tenantContext,
          fullNameController: fullNameController,
          emailController: emailController,
          phoneController: phoneController,
          permissionOverride: permissionOverride,
          sendInvite: sendInvite,
          isSaving: isSaving,
          showPermissionToggle: canOverride,
          onRoleSelected: onRoleSelected,
          onOutletChanged: onOutletChanged,
          onPermissionOverrideChanged: onPermissionOverrideChanged,
          onSendInviteChanged: onSendInviteChanged,
          onCancel: onCancel,
          onSave: onSave,
        );
        final panel = _PermissionOverridePanel(
          roleName: selectedRole ?? 'Manager',
          tenantContext: tenantContext,
          selectedOutlets: selectedOutlets,
        );

        if (!showPanel || !wide) {
          return Column(
            children: [
              form,
              if (showPanel) ...[
                const SizedBox(height: TenantAdminSpacing.xl),
                panel,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: form),
            const SizedBox(width: TenantAdminSpacing.xl),
            Expanded(flex: 5, child: panel),
          ],
        );
      },
    );
  }
}

class _AddUserMainCard extends StatelessWidget {
  const _AddUserMainCard({
    required this.selectedRole,
    required this.selectedOutlets,
    required this.tenantContext,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.permissionOverride,
    required this.sendInvite,
    required this.isSaving,
    required this.showPermissionToggle,
    required this.onRoleSelected,
    required this.onOutletChanged,
    required this.onPermissionOverrideChanged,
    required this.onSendInviteChanged,
    required this.onCancel,
    required this.onSave,
  });

  final String? selectedRole;
  final Set<String> selectedOutlets;
  final TenantAdminContext tenantContext;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final bool permissionOverride;
  final bool sendInvite;
  final bool isSaving;
  final bool showPermissionToggle;
  final ValueChanged<String?> onRoleSelected;
  final void Function(String outletId, bool selected) onOutletChanged;
  final ValueChanged<bool> onPermissionOverrideChanged;
  final ValueChanged<bool> onSendInviteChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final roleNames = tenantContext.roleNames.isEmpty
        ? const ['Tenant Admin', 'Manager', 'Cashier', 'Staff']
        : tenantContext.roleNames;
    final outletNames = tenantContext.outletScope
        .where((outlet) => selectedOutlets.contains(outlet.outletId))
        .map((outlet) => outlet.outletName)
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 680;
              final fields = [
                _FormInput(
                  label: 'Full Name',
                  hint: 'Enter full name',
                  icon: Icons.person_outline,
                  controller: fullNameController,
                ),
                _FormInput(
                  label: 'Email',
                  hint: 'Enter email address',
                  icon: Icons.mail_outline,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                _FormInput(
                  label: 'Phone',
                  hint: 'Enter phone number',
                  icon: Icons.phone_outlined,
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                ),
                _SelectBox(
                  label: 'Role',
                  icon: Icons.shield_outlined,
                  value: selectedRole ?? 'Select a role',
                  options: roleNames,
                  onSelected: onRoleSelected,
                ),
              ];

              if (!twoColumns) {
                return Column(
                  children: [
                    for (final field in fields) ...[
                      field,
                      const SizedBox(height: TenantAdminSpacing.lg),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(child: fields[1]),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Row(
                    children: [
                      Expanded(child: fields[2]),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(child: fields[3]),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                ],
              );
            },
          ),
          _OutletSelectBox(
            value: outletNames.isEmpty ? 'Select outlet(s)' : outletNames,
            outlets: tenantContext.outletScope,
            selectedOutlets: selectedOutlets,
            onChanged: onOutletChanged,
          ),
          if (showPermissionToggle) ...[
            const SizedBox(height: TenantAdminSpacing.xl),
            _ToggleRow(
              title: 'Permission Override',
              subtitle: selectedRole == null
                  ? 'Select a role first to enable permission override.'
                  : 'Customize permissions for this user.',
              value: permissionOverride,
              onChanged:
                  selectedRole == null ? null : onPermissionOverrideChanged,
              info: true,
            ),
          ],
          const Divider(height: TenantAdminSpacing.xxl),
          _ToggleRow(
            title: 'Send Invite Email After Save',
            subtitle:
                'Send an email invitation to the user with login instructions.',
            value: sendInvite,
            onChanged: onSendInviteChanged,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Preview',
                  style: TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                const _UserStatusBadge(status: 'Invited'),
                const SizedBox(height: TenantAdminSpacing.sm),
                Text(
                  'The user will be invited and must accept the invitation to activate their account.',
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          Text(
            'Profile Image  (Optional)',
            style: TenantAdminTextStyles.sectionTitle(context).copyWith(
              fontSize: 14,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          const _ProfileUploadBox(),
          const SizedBox(height: TenantAdminSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TenantAdminSecondaryButton(
                label: 'Cancel',
                onPressed: onCancel,
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              TenantAdminPrimaryButton(
                label: isSaving ? 'Saving...' : 'Save User',
                onPressed: onSave,
                loading: isSaving,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        PopupMenuButton<String>(
          onSelected: onSelected,
          itemBuilder: (context) => [
            for (final option in options)
              PopupMenuItem(value: option, child: Text(option)),
          ],
          child: Container(
            height: 52,
            padding:
                const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
            decoration: BoxDecoration(
              color: TenantAdminColors.surface,
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 19, color: TenantAdminColors.mutedText),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(child: Text(value)),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OutletSelectBox extends StatelessWidget {
  const _OutletSelectBox({
    required this.value,
    required this.outlets,
    required this.selectedOutlets,
    required this.onChanged,
  });

  final String value;
  final List<TenantAdminOutletScope> outlets;
  final Set<String> selectedOutlets;
  final void Function(String outletId, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Outlets',
          style: TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        PopupMenuButton<String>(
          onSelected: (outletId) =>
              onChanged(outletId, !selectedOutlets.contains(outletId)),
          itemBuilder: (context) => [
            for (final outlet in outlets)
              CheckedPopupMenuItem(
                value: outlet.outletId,
                checked: selectedOutlets.contains(outlet.outletId),
                child: Text(outlet.outletName),
              ),
          ],
          child: Container(
            height: 52,
            padding:
                const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
            decoration: BoxDecoration(
              color: TenantAdminColors.surface,
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 19,
                  color: TenantAdminColors.mutedText,
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(child: Text(value)),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.info = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool info;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (info) ...[
                    const SizedBox(width: TenantAdminSpacing.sm),
                    const Icon(
                      Icons.info_outline,
                      color: TenantAdminColors.mutedText,
                      size: 16,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                subtitle,
                style: TenantAdminTextStyles.muted(context).copyWith(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileUploadBox extends StatelessWidget {
  const _ProfileUploadBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: TenantAdminColors.primary.withValues(alpha: 0.35),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            color: TenantAdminColors.primary,
            size: 32,
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          const Text(
            'Upload image',
            style: TextStyle(
              color: TenantAdminColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'JPG, PNG up to 2MB',
            style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PermissionOverridePanel extends StatelessWidget {
  const _PermissionOverridePanel({
    required this.roleName,
    required this.tenantContext,
    required this.selectedOutlets,
  });

  final String roleName;
  final TenantAdminContext tenantContext;
  final Set<String> selectedOutlets;

  @override
  Widget build(BuildContext context) {
    final permissions = tenantContext.permissions.take(14).toList();
    final outlets = tenantContext.outletScope.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permission Override',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'Review and adjust permissions inherited from the selected role.',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _RoleBadge(label: 'Role: $roleName'),
          const SizedBox(height: TenantAdminSpacing.xl),
          if (permissions.isEmpty)
            const TenantAdminEmptyState(
              title: 'No permission catalog available',
              message: 'Tenant context did not return permission data.',
              icon: Icons.key_off_outlined,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: permissions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: TenantAdminSpacing.lg,
                mainAxisSpacing: TenantAdminSpacing.sm,
                childAspectRatio: 5,
              ),
              itemBuilder: (context, index) {
                final permission = permissions[index];
                return CheckboxListTile(
                  value: index % 4 != 3,
                  onChanged: (_) {},
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    permission.permissionName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          const Divider(height: TenantAdminSpacing.xxl),
          Text(
            'Outlet Access',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Wrap(
            spacing: TenantAdminSpacing.lg,
            runSpacing: TenantAdminSpacing.sm,
            children: [
              for (final outlet in outlets)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: selectedOutlets.contains(outlet.outletId),
                      onChanged: (_) {},
                    ),
                    Text(outlet.outletName),
                  ],
                ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          TenantAdminSecondaryButton(
            label: 'Reset to Role Defaults',
            icon: Icons.refresh,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _AddStaffWizard extends StatelessWidget {
  const _AddStaffWizard({
    required this.stepIndex,
    required this.selectedRole,
    required this.selectedOutlets,
    required this.tenantContext,
    required this.access,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.mobileController,
    required this.staffCodeController,
    required this.jobTitleController,
    required this.notesController,
    required this.onBack,
    required this.onContinue,
    required this.onRoleSelected,
    required this.onOutletChanged,
    required this.onSaveDraft,
    required this.onSendInvite,
  });

  final int stepIndex;
  final String? selectedRole;
  final Set<String> selectedOutlets;
  final TenantAdminContext tenantContext;
  final TenantAdminAccessChecker access;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController staffCodeController;
  final TextEditingController jobTitleController;
  final TextEditingController notesController;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final ValueChanged<String> onRoleSelected;
  final void Function(String outletId, bool selected) onOutletChanged;
  final VoidCallback onSaveDraft;
  final VoidCallback? onSendInvite;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StaffStepper(currentStep: stepIndex),
        const SizedBox(height: TenantAdminSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 700;
            final form = _WizardBody(
              stepIndex: stepIndex,
              selectedRole: selectedRole,
              selectedOutlets: selectedOutlets,
              tenantContext: tenantContext,
              access: access,
              firstNameController: firstNameController,
              lastNameController: lastNameController,
              emailController: emailController,
              mobileController: mobileController,
              staffCodeController: staffCodeController,
              jobTitleController: jobTitleController,
              notesController: notesController,
              onRoleSelected: onRoleSelected,
              onOutletChanged: onOutletChanged,
            );
            const helper = _StaffHelperPanel();

            if (stack) {
              return Column(
                children: [
                  form,
                  const SizedBox(height: TenantAdminSpacing.lg),
                  helper,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: form),
                const SizedBox(width: TenantAdminSpacing.xl),
                const Expanded(flex: 3, child: helper),
              ],
            );
          },
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        _WizardFooter(
          stepIndex: stepIndex,
          onBack: onBack,
          onSaveDraft: onSaveDraft,
          onContinue: stepIndex == 3 ? onSendInvite : onContinue,
          continueLabel: stepIndex == 3 ? 'Send invite' : 'Continue',
        ),
      ],
    );
  }
}

class _StaffStepper extends StatelessWidget {
  const _StaffStepper({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Basic details',
      'Choose role',
      'Outlet access',
      'Review & invite',
    ];

    return Container(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TenantAdminColors.border)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Expanded(
              child: _StepperItem(
                number: index + 1,
                label: steps[index],
                selected: index == currentStep,
                done: index < currentStep,
              ),
            ),
            if (index != steps.length - 1)
              Container(
                width: 34,
                height: 2,
                color: index < currentStep
                    ? TenantAdminColors.primary
                    : TenantAdminColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _StepperItem extends StatelessWidget {
  const _StepperItem({
    required this.number,
    required this.label,
    required this.selected,
    required this.done,
  });

  final int number;
  final String label;
  final bool selected;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = selected || done
        ? TenantAdminColors.primary
        : TenantAdminColors.mutedText.withValues(alpha: 0.36);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: selected || done
              ? TenantAdminColors.primary
              : TenantAdminColors.surface,
          foregroundColor:
              selected || done ? Colors.white : TenantAdminColors.mutedText,
          child: Text(
            '$number',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? TenantAdminColors.bodyText : color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _WizardBody extends StatelessWidget {
  const _WizardBody({
    required this.stepIndex,
    required this.selectedRole,
    required this.selectedOutlets,
    required this.tenantContext,
    required this.access,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.mobileController,
    required this.staffCodeController,
    required this.jobTitleController,
    required this.notesController,
    required this.onRoleSelected,
    required this.onOutletChanged,
  });

  final int stepIndex;
  final String? selectedRole;
  final Set<String> selectedOutlets;
  final TenantAdminContext tenantContext;
  final TenantAdminAccessChecker access;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController staffCodeController;
  final TextEditingController jobTitleController;
  final TextEditingController notesController;
  final ValueChanged<String> onRoleSelected;
  final void Function(String outletId, bool selected) onOutletChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: _cardDecoration(),
      child: switch (stepIndex) {
        0 => _BasicDetailsForm(
            firstNameController: firstNameController,
            lastNameController: lastNameController,
            emailController: emailController,
            mobileController: mobileController,
            staffCodeController: staffCodeController,
            jobTitleController: jobTitleController,
            notesController: notesController,
          ),
        1 => _ChooseRoleStep(
            roleNames: tenantContext.roleNames,
            selectedRole: selectedRole,
            canAssignRole: access.canAny(_staffRoleAssignPermissions),
            onRoleSelected: onRoleSelected,
          ),
        2 => _OutletAccessStep(
            outlets: tenantContext.outletScope,
            selectedOutlets: selectedOutlets,
            canAssignOutlet: access.canAny(_staffOutletAssignPermissions),
            onOutletChanged: onOutletChanged,
          ),
        _ => _ReviewInviteStep(
            selectedRole: selectedRole,
            selectedOutlets: selectedOutlets,
            tenantContext: tenantContext,
            firstName: firstNameController.text,
            lastName: lastNameController.text,
            email: emailController.text,
            mobile: mobileController.text,
            staffCode: staffCodeController.text,
            jobTitle: jobTitleController.text,
          ),
      },
    );
  }
}

class _BasicDetailsForm extends StatelessWidget {
  const _BasicDetailsForm({
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.mobileController,
    required this.staffCodeController,
    required this.jobTitleController,
    required this.notesController,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController staffCodeController;
  final TextEditingController jobTitleController;
  final TextEditingController notesController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Staff information',
            style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(height: TenantAdminSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 520;

            if (!twoColumns) {
              return Column(
                children: [
                  _FormInput(
                    label: 'First name',
                    hint: 'Enter first name',
                    icon: Icons.person_outline,
                    controller: firstNameController,
                    helper: 'Use the staff member’s real first name.',
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  _FormInput(
                    label: 'Last name',
                    hint: 'Enter last name',
                    icon: Icons.person_outline,
                    controller: lastNameController,
                    helper: 'Use the staff member’s real last name.',
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FormInput(
                    label: 'First name',
                    hint: 'Enter first name',
                    icon: Icons.person_outline,
                    controller: firstNameController,
                    helper: 'Use the staff member’s real first name.',
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(
                  child: _FormInput(
                    label: 'Last name',
                    hint: 'Enter last name',
                    icon: Icons.person_outline,
                    controller: lastNameController,
                    helper: 'Use the staff member’s real last name.',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _FormInput(
          label: 'Email address',
          hint: 'Enter email address',
          icon: Icons.mail_outline,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          helper: 'Add a valid email address for invites and notifications.',
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _FormInput(
          label: 'Mobile number',
          hint: 'Enter mobile number',
          icon: Icons.phone_outlined,
          controller: mobileController,
          keyboardType: TextInputType.phone,
          helper: 'Include country code, e.g. +44 7700 900123.',
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 520;
            final staffCode = _FormInput(
              label: 'Staff code',
              hint: 'Enter staff code',
              icon: Icons.badge_outlined,
              controller: staffCodeController,
              helper: 'Use a unique code to identify this staff member.',
            );
            final jobTitle = _FormInput(
              label: 'Job title (optional)',
              hint: 'Enter job title',
              icon: Icons.work_outline,
              controller: jobTitleController,
              helper: 'E.g. Cashier, Store Manager, Supervisor.',
            );

            if (!twoColumns) {
              return Column(
                children: [
                  staffCode,
                  const SizedBox(height: TenantAdminSpacing.lg),
                  jobTitle,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: staffCode),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(child: jobTitle),
              ],
            );
          },
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _FormInput(
          label: 'Notes (optional)',
          hint: 'Add any notes about this staff member',
          icon: Icons.note_alt_outlined,
          controller: notesController,
          helper: 'Internal notes are only visible to admins.',
        ),
      ],
    );
  }
}

class _ChooseRoleStep extends StatelessWidget {
  const _ChooseRoleStep({
    required this.roleNames,
    required this.selectedRole,
    required this.canAssignRole,
    required this.onRoleSelected,
  });

  final List<String> roleNames;
  final String? selectedRole;
  final bool canAssignRole;
  final ValueChanged<String> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    if (!canAssignRole) {
      return const TenantAdminEmptyState(
        title: 'Role assignment unavailable',
        message: 'You do not have permission to assign staff roles.',
        icon: Icons.shield_outlined,
      );
    }

    if (roleNames.isEmpty) {
      return const TenantAdminEmptyState(
        title: 'No role options available',
        message: 'Role provider is not available yet for staff creation.',
        icon: Icons.admin_panel_settings_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose role', style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(height: TenantAdminSpacing.sm),
        Text(
          'Select one role for this staff member.',
          style: TenantAdminTextStyles.muted(context),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        for (final role in roleNames) ...[
          _SelectableTile(
            title: role,
            subtitle: 'Existing tenant role',
            icon: Icons.shield_outlined,
            selected: selectedRole == role,
            onTap: () => onRoleSelected(role),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
        ],
      ],
    );
  }
}

class _OutletAccessStep extends StatelessWidget {
  const _OutletAccessStep({
    required this.outlets,
    required this.selectedOutlets,
    required this.canAssignOutlet,
    required this.onOutletChanged,
  });

  final List<TenantAdminOutletScope> outlets;
  final Set<String> selectedOutlets;
  final bool canAssignOutlet;
  final void Function(String outletId, bool selected) onOutletChanged;

  @override
  Widget build(BuildContext context) {
    if (!canAssignOutlet) {
      return const TenantAdminEmptyState(
        title: 'Outlet assignment unavailable',
        message: 'You do not have permission to assign outlet access.',
        icon: Icons.store_outlined,
      );
    }

    if (outlets.isEmpty) {
      return const TenantAdminEmptyState(
        title: 'No outlets available',
        message: 'Outlet access data is not available for this tenant.',
        icon: Icons.store_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Outlet access',
            style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(height: TenantAdminSpacing.sm),
        Text(
          'Choose which outlets this staff member can access.',
          style: TenantAdminTextStyles.muted(context),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        for (final outlet in outlets) ...[
          CheckboxListTile(
            value: selectedOutlets.contains(outlet.outletId),
            onChanged: (value) =>
                onOutletChanged(outlet.outletId, value ?? false),
            title: Text(
              outlet.outletName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(outlet.outletId),
            secondary: const _IconTile(
              icon: Icons.storefront_outlined,
              color: TenantAdminColors.primary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              side: const BorderSide(color: TenantAdminColors.border),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
        ],
      ],
    );
  }
}

class _ReviewInviteStep extends StatelessWidget {
  const _ReviewInviteStep({
    required this.selectedRole,
    required this.selectedOutlets,
    required this.tenantContext,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.staffCode,
    required this.jobTitle,
  });

  final String? selectedRole;
  final Set<String> selectedOutlets;
  final TenantAdminContext tenantContext;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String staffCode;
  final String jobTitle;

  @override
  Widget build(BuildContext context) {
    final outletNames = tenantContext.outletScope
        .where((outlet) => selectedOutlets.contains(outlet.outletId))
        .map((outlet) => outlet.outletName)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & invite',
            style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(height: TenantAdminSpacing.lg),
        _ReviewRow(label: 'Name', value: _fallback('$firstName $lastName')),
        _ReviewRow(label: 'Email', value: _fallback(email)),
        _ReviewRow(label: 'Mobile', value: _fallback(mobile)),
        _ReviewRow(label: 'Staff code', value: _fallback(staffCode)),
        _ReviewRow(label: 'Job title', value: _fallback(jobTitle)),
        _ReviewRow(label: 'Role', value: selectedRole ?? 'Not selected'),
        _ReviewRow(
          label: 'Outlet access',
          value: outletNames.isEmpty ? 'Not selected' : outletNames,
        ),
      ],
    );
  }
}

class _StaffHelperPanel extends StatelessWidget {
  const _StaffHelperPanel();

  @override
  Widget build(BuildContext context) {
    const items = [
      _HelperItem(
        icon: Icons.person_outline,
        title: 'Use the staff member’s real name',
      ),
      _HelperItem(
        icon: Icons.mail_outline,
        title: 'Add the best contact details',
      ),
      _HelperItem(
        icon: Icons.storefront_outlined,
        title: 'You’ll choose role and outlet access next',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TenantAdminColors.primary.withValues(alpha: 0.08),
            TenantAdminColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before you continue',
            style: TenantAdminTextStyles.sectionTitle(context).copyWith(
              color: TenantAdminColors.primary,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconTile(icon: item.icon, color: TenantAdminColors.primary),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (item != items.last)
              const SizedBox(height: TenantAdminSpacing.xl),
          ],
        ],
      ),
    );
  }
}

class _WizardFooter extends StatelessWidget {
  const _WizardFooter({
    required this.stepIndex,
    required this.onBack,
    required this.onSaveDraft,
    required this.onContinue,
    required this.continueLabel,
  });

  final int stepIndex;
  final VoidCallback onBack;
  final VoidCallback onSaveDraft;
  final VoidCallback? onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TenantAdminSecondaryButton(
          label: stepIndex == 0 ? 'Back' : 'Previous',
          icon: Icons.arrow_back,
          onPressed: onBack,
        ),
        const Spacer(),
        TenantAdminSecondaryButton(
          label: 'Save draft',
          icon: Icons.save_outlined,
          onPressed: onSaveDraft,
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        TenantAdminPrimaryButton(
          label: continueLabel,
          icon: stepIndex == 3 ? Icons.send_outlined : Icons.arrow_forward,
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _FormInput extends StatelessWidget {
  const _FormInput({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.helper,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final String? helper;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 19),
            filled: true,
            fillColor: TenantAdminColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.primary),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            helper!,
            style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? TenantAdminColors.primary.withValues(alpha: 0.08)
              : TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(
            color:
                selected ? TenantAdminColors.primary : TenantAdminColors.border,
          ),
        ),
        child: Row(
          children: [
            _IconTile(icon: icon, color: TenantAdminColors.primary),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(subtitle, style: TenantAdminTextStyles.muted(context)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
                  ? TenantAdminColors.primary
                  : TenantAdminColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: TenantAdminColors.bodyText,
        side: const BorderSide(color: TenantAdminColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        ),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  const _PaginationButton({
    required this.icon,
    required this.enabled,
  });

  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TenantAdminIconButton(
      icon: icon,
      onPressed: enabled ? () {} : null,
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? TenantAdminColors.primary : TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(
          color:
              selected ? TenantAdminColors.primary : TenantAdminColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : TenantAdminColors.bodyText,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RowsPerPageButton extends StatelessWidget {
  const _RowsPerPageButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('10 per page'),
          SizedBox(width: TenantAdminSpacing.sm),
          Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TenantAdminColors.offline.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyTableText extends StatelessWidget {
  const _EmptyTableText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TenantAdminTextStyles.muted(context));
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TenantAdminColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TenantAdminTextStyles.muted(context)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: TenantAdminColors.surface,
    borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
    border: Border.all(color: TenantAdminColors.border),
    boxShadow: TenantAdminShadows.card,
  );
}

String _fallback(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'Not entered' : trimmed;
}

Map<String, List<TenantAdminPermission>> _groupPermissions(
  List<TenantAdminPermission> permissions,
) {
  final grouped = <String, List<TenantAdminPermission>>{};
  for (final permission in permissions) {
    final moduleName = permission.permissionCode.split('.').first;
    grouped.putIfAbsent(moduleName, () => []).add(permission);
  }

  return grouped;
}

const _roleAccessViewPermissions = [
  TenantAdminPermissionCodes.roleView,
  TenantAdminPermissionCodes.permissionView,
  TenantAdminPermissionCodes.tenantRoleManage,
];

const _roleAccessManagePermissions = [
  TenantAdminPermissionCodes.tenantRoleManage,
];

const _staffViewPermissions = [
  TenantAdminPermissionCodes.userView,
  TenantAdminPermissionCodes.tenantUserManage,
];

const _staffCreatePermissions = [
  TenantAdminPermissionCodes.userCreate,
  TenantAdminPermissionCodes.userInviteCreate,
  TenantAdminPermissionCodes.tenantUserManage,
];

const _staffDetailPermissions = [
  TenantAdminPermissionCodes.userView,
  TenantAdminPermissionCodes.tenantUserManage,
];

const _staffEditPermissions = [
  TenantAdminPermissionCodes.tenantUserManage,
];

const _staffInvitePermissions = [
  TenantAdminPermissionCodes.userInviteCreate,
  TenantAdminPermissionCodes.tenantUserManage,
];

const _staffRoleAssignPermissions = [
  TenantAdminPermissionCodes.tenantUserManage,
];

const _staffOutletAssignPermissions = [
  TenantAdminPermissionCodes.tenantUserManage,
];

const _staffPermissionOverridePermissions = [
  TenantAdminPermissionCodes.tenantRoleManage,
  'roles.permissions.update',
];

const _productViewPermissions = [
  TenantAdminPermissionCodes.productView,
  TenantAdminPermissionCodes.catalogProductView,
];

const _productCreatePermissions = [
  TenantAdminPermissionCodes.productCreate,
  TenantAdminPermissionCodes.catalogProductCreate,
];

const _productDetailPermissions = [
  TenantAdminPermissionCodes.productView,
  TenantAdminPermissionCodes.catalogProductView,
];

const _productEditPermissions = [
  'catalog.product.update',
];

const _productStatusPermissions = <String>[];

const _productDeletePermissions = <String>[];

const _productCategoryViewPermissions = [
  TenantAdminPermissionCodes.productView,
  TenantAdminPermissionCodes.catalogProductView,
];

const _productPricePermissions = <String>[];

const _productTaxPermissions = <String>[];

const _productStockPermissions = <String>[];

const _productOutletAssignPermissions = <String>[];

const _productImagePermissions = <String>[];

class _ChipData {
  const _ChipData(this.label, this.count);

  final String label;
  final String? count;
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _HelperItem {
  const _HelperItem({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;
}
