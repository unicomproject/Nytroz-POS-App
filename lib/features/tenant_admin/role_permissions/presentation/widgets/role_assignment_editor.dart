import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/role_assignment.dart';

class RoleAssignmentEditor extends StatelessWidget {
  const RoleAssignmentEditor({
    super.key,
    required this.options,
    required this.assignments,
    required this.onChanged,
  });

  final RoleAssignmentOptions options;
  final List<RoleAssignment> assignments;
  final ValueChanged<List<RoleAssignment>> onChanged;

  @override
  Widget build(BuildContext context) {
    final assignmentsByUser = {
      for (final assignment in assignments) assignment.userId: assignment,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assign users',
            style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          options.canAssignUsers
              ? 'Select the users who should receive this role.'
              : 'You do not have permission to add or remove users.',
          style: TenantAdminTextStyles.muted(context),
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        if (options.users.isEmpty)
          const Text('No eligible users are available.')
        else
          ...options.users.map((user) {
            final selected = assignmentsByUser.containsKey(user.id);
            return CheckboxListTile(
              value: selected,
              onChanged: options.canAssignUsers
                  ? (value) => _toggleUser(user, value ?? false)
                  : null,
              title: Text(user.fullName),
              subtitle: Text('${user.email} · ${user.status}'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            );
          }),
        if (assignments.isNotEmpty) ...[
          const Divider(height: TenantAdminSpacing.xxl),
          Text('Outlet access',
              style: TenantAdminTextStyles.sectionTitle(context)),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            options.canAssignOutlets
                ? 'Set tenant-wide or selected-outlet access for each assigned user.'
                : 'You do not have permission to change outlet access.',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          ...assignments.map(_assignmentCard),
        ],
      ],
    );
  }

  Widget _assignmentCard(RoleAssignment assignment) {
    RoleAssignmentUserOption? user;
    for (final option in options.users) {
      if (option.id == assignment.userId) {
        user = option;
        break;
      }
    }
    final displayName =
        assignment.fullName ?? user?.fullName ?? assignment.userId;
    return Card(
      margin: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayName,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            RadioListTile<RoleAccessScopeType>(
              value: RoleAccessScopeType.tenantWide,
              groupValue: assignment.scopeType,
              onChanged: options.canAssignOutlets
                  ? (value) => _setScope(assignment, value!)
                  : null,
              title: const Text('Tenant-wide access'),
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<RoleAccessScopeType>(
              value: RoleAccessScopeType.selectedOutlets,
              groupValue: assignment.scopeType,
              onChanged: options.canAssignOutlets
                  ? (value) => _setScope(assignment, value!)
                  : null,
              title: const Text('Selected outlets'),
              contentPadding: EdgeInsets.zero,
            ),
            if (assignment.scopeType == RoleAccessScopeType.selectedOutlets)
              ...options.outlets.map(
                (outlet) => CheckboxListTile(
                  value: assignment.outletIds.contains(outlet.id),
                  onChanged: options.canAssignOutlets
                      ? (_) => _toggleOutlet(assignment, outlet.id)
                      : null,
                  title: Text(outlet.name),
                  subtitle: Text(outlet.code),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding:
                      const EdgeInsets.only(left: TenantAdminSpacing.lg),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleUser(RoleAssignmentUserOption user, bool selected) {
    final next = List<RoleAssignment>.from(assignments)
      ..removeWhere((item) => item.userId == user.id);
    if (selected) {
      next.add(RoleAssignment(
        userId: user.id,
        scopeType: RoleAccessScopeType.tenantWide,
        outletIds: const [],
        fullName: user.fullName,
        email: user.email,
      ));
    }
    onChanged(next);
  }

  void _setScope(RoleAssignment assignment, RoleAccessScopeType scope) {
    _replace(RoleAssignment(
      userId: assignment.userId,
      scopeType: scope,
      outletIds: scope == RoleAccessScopeType.tenantWide
          ? const []
          : assignment.outletIds,
      fullName: assignment.fullName,
      email: assignment.email,
    ));
  }

  void _toggleOutlet(RoleAssignment assignment, String outletId) {
    final outletIds = Set<String>.from(assignment.outletIds);
    if (!outletIds.add(outletId)) {
      outletIds.remove(outletId);
    }
    _replace(RoleAssignment(
      userId: assignment.userId,
      scopeType: assignment.scopeType,
      outletIds: outletIds.toList()..sort(),
      fullName: assignment.fullName,
      email: assignment.email,
    ));
  }

  void _replace(RoleAssignment replacement) {
    onChanged([
      for (final assignment in assignments)
        if (assignment.userId == replacement.userId)
          replacement
        else
          assignment,
    ]);
  }
}
