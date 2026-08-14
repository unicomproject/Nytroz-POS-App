import 'package:flutter/material.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_user.dart';
import '../config/user_row_action_configs.dart';
import '../utils/user_api_errors.dart';
import 'user_status_badge.dart';

class UserTable extends StatelessWidget {
  const UserTable({
    super.key,
    required this.users,
    required this.visibility,
    required this.selectedUserId,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TenantUser> users;
  final UserListVisibility visibility;
  final String? selectedUserId;
  final ValueChanged<TenantUser> onView;
  final ValueChanged<TenantUser> onEdit;
  final ValueChanged<TenantUser> onDelete;

  @override
  Widget build(BuildContext context) {
    final canView = visibility.visibleRowActions
        .any((action) => action.actionId == UserRowActionId.viewDetails);
    final canEdit = visibility.visibleRowActions
        .any((action) => action.actionId == UserRowActionId.edit);
    final canDeactivate = visibility.visibleRowActions
        .any((action) => action.actionId == UserRowActionId.delete);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: _UserRowHeader(),
        ),
        for (final user in users)
          _UserRow(
            user: user,
            selected: user.id == selectedUserId,
            canView: canView,
            canEdit: canEdit,
            canDeactivate: canDeactivate,
            onView: onView,
            onEdit: onEdit,
            onDeactivate: onDelete,
          ),
      ],
    );
  }
}

class _UserRowHeader extends StatelessWidget {
  const _UserRowHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: TenantAdminColors.mutedText,
      fontSize: 10,
      fontWeight: FontWeight.w800,
    );
    return const Row(
      children: [
        Expanded(flex: 25, child: Text('USER', style: style)),
        Expanded(flex: 16, child: Text('ROLE', style: style)),
        Expanded(flex: 17, child: Text('OUTLET ACCESS', style: style)),
        Expanded(flex: 13, child: Text('LAST ACTIVE', style: style)),
        Expanded(flex: 12, child: Text('STATUS', style: style)),
        Expanded(flex: 17, child: Text('ACTIONS', style: style)),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.selected,
    required this.canView,
    required this.canEdit,
    required this.canDeactivate,
    required this.onView,
    required this.onEdit,
    required this.onDeactivate,
  });

  final TenantUser user;
  final bool selected;
  final bool canView;
  final bool canEdit;
  final bool canDeactivate;
  final ValueChanged<TenantUser> onView;
  final ValueChanged<TenantUser> onEdit;
  final ValueChanged<TenantUser> onDeactivate;

  @override
  Widget build(BuildContext context) {
    final outline = selected
        ? TenantAdminColors.posHomeAccentOrange
        : TenantAdminColors.border;

    return Semantics(
      selected: selected,
      button: canView,
      label: 'User ${user.fullName}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Material(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          child: InkWell(
            onTap: canView ? () => onView(user) : null,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            child: Container(
              padding: const EdgeInsets.all(TenantAdminSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                border: Border.all(color: outline, width: selected ? 1.5 : 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 25, child: _Identity(user: user)),
                  Expanded(flex: 16, child: _Role(user: user)),
                  Expanded(flex: 17, child: _OutletAccess(user: user)),
                  Expanded(flex: 13, child: _LastActive(user: user)),
                  Expanded(
                      flex: 12, child: UserStatusBadge(status: user.status)),
                  Expanded(
                    flex: 17,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (canView)
                          _TextAction(
                            label: 'View',
                            onPressed: () => onView(user),
                          ),
                        if (canEdit)
                          _TextAction(
                            label: 'Edit',
                            onPressed: () => onEdit(user),
                          ),
                        if (canDeactivate)
                          _TextAction(
                            label: 'Deactivate',
                            destructive: true,
                            onPressed: () => onDeactivate(user),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.user});

  final TenantUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: TenantAdminColors.secondary,
          child: Text(_initials(user.fullName),
              style: const TextStyle(
                  color: TenantAdminColors.posHomeAccentOrange,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: TenantAdminColors.bodyText)),
              Text(user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.muted(context)
                      .copyWith(fontSize: 11)),
              if ((user.phone ?? '').trim().isNotEmpty)
                Text(user.phone!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TenantAdminTextStyles.muted(context)
                        .copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Role extends StatelessWidget {
  const _Role({required this.user});
  final TenantUser user;
  @override
  Widget build(BuildContext context) => _TwoLineCell(
        primary: _dash(user.roleName),
        secondary: _nonEmpty(user.roleDescription),
      );
}

class _OutletAccess extends StatelessWidget {
  const _OutletAccess({required this.user});
  final TenantUser user;
  @override
  Widget build(BuildContext context) {
    final names = user.outlets
        .map((outlet) => outlet.name)
        .where((name) => name.trim().isNotEmpty)
        .toList();
    final count = user.outletCount ?? names.length;
    return _TwoLineCell(
      primary:
          names.isNotEmpty ? names.take(2).join(', ') : _dash(user.outletName),
      secondary:
          count > 0 ? '$count ${count == 1 ? 'Outlet' : 'Outlets'}' : null,
    );
  }
}

class _LastActive extends StatelessWidget {
  const _LastActive({required this.user});
  final TenantUser user;
  @override
  Widget build(BuildContext context) => _TwoLineCell(
        primary: formatUserLastActive(user.lastActiveAt),
        secondary: user.lastActiveAt == null
            ? null
            : formatUserDate(user.lastActiveAt),
      );
}

class _TwoLineCell extends StatelessWidget {
  const _TwoLineCell({required this.primary, this.secondary});
  final String primary;
  final String? secondary;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(primary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          if (secondary != null)
            Text(secondary!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TenantAdminTextStyles.muted(context)
                    .copyWith(fontSize: 11)),
        ],
      );
}

class _TextAction extends StatelessWidget {
  const _TextAction(
      {required this.label, required this.onPressed, this.destructive = false});
  final String label;
  final VoidCallback onPressed;
  final bool destructive;
  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor:
              destructive ? TenantAdminColors.danger : TenantAdminColors.info,
          minimumSize: const Size(0, 30),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      );
}

String? _nonEmpty(String? value) =>
    value?.trim().isNotEmpty == true ? value!.trim() : null;
String _dash(String value) => value.trim().isEmpty ? '—' : value.trim();
String _initials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
