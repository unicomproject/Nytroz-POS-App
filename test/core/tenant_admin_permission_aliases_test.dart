import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_permission_aliases.dart';

void main() {
  test('settings manage does not accept view-only permissions', () {
    expect(
      TenantAdminPermissionAliases.expand('tenant.settings.manage'),
      ['tenant.settings.manage'],
    );
  });

  test('legacy settings view accepts the canonical manage permission', () {
    expect(
      TenantAdminPermissionAliases.expand('tenant_settings.view'),
      contains('tenant.settings.manage'),
    );
  });

  test('outlet manage is not granted by a single outlet action', () {
    expect(
      TenantAdminPermissionAliases.expand('tenant.outlets.manage'),
      ['tenant.outlets.manage'],
    );
  });

  test('role manage is not granted by role view permission', () {
    expect(
      TenantAdminPermissionAliases.expand('tenant.roles.manage'),
      ['tenant.role.manage', 'tenant.roles.manage'],
    );
  });

  test('legacy outlet actions accept their canonical action permissions', () {
    expect(
      TenantAdminPermissionAliases.expand('outlet.create'),
      contains('tenant.outlets.create'),
    );
    expect(
      TenantAdminPermissionAliases.expand('outlet.delete'),
      contains('tenant.outlets.delete'),
    );
  });

  test('user manage grants all user mutation actions', () {
    for (final permission in [
      'tenant.users.create',
      'tenant.users.invite',
      'tenant.users.update',
      'tenant.users.delete',
      'tenant.users.disable',
      'tenant.users.roles.assign',
      'tenant.users.outlets.assign',
      'tenant.users.tills.assign',
      'tenant.users.invites.resend',
      'tenant.users.invites.revoke',
    ]) {
      expect(
        TenantAdminPermissionAliases.expand(permission),
        contains('tenant.users.manage'),
      );
    }
  });

  test('legacy role assignment update does not grant granular assignments', () {
    expect(
      TenantAdminPermissionAliases.expand('tenant.roles.users.assign'),
      isNot(contains('tenant.roles.assignments.update')),
    );
    expect(
      TenantAdminPermissionAliases.expand('tenant.roles.outlets.assign'),
      isNot(contains('tenant.roles.assignments.update')),
    );
  });

  test('canonical till manage grants all till actions', () {
    for (final permission in [
      'tenant.tills.view',
      'tenant.tills.create',
      'tenant.tills.update',
      'tenant.tills.delete',
      'tenant.tills.assign_outlet',
    ]) {
      expect(
        TenantAdminPermissionAliases.expand(permission),
        contains('tenant.tills.manage'),
      );
    }
  });
}
