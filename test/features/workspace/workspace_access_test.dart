import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/workspace/domain/workspace_access.dart';

void main() {
  group('resolveWorkspaceAccess', () {
    test('grants only Tenant Admin for admin permissions', () {
      final access = resolveWorkspaceAccess(const [
        'workspace.tenant_admin.access',
        'tenant.users.view',
      ]);

      expect(access.canAccessTenantAdmin, isTrue);
      expect(access.canAccessPos, isFalse);
      expect(access.onlyWorkspace, AppWorkspace.tenantAdmin);
    });

    test('grants only POS for cashier permissions', () {
      final access = resolveWorkspaceAccess(const [
        'workspace.pos.access',
        'pos.home.view',
        'pos.till.open',
      ]);

      expect(access.canAccessTenantAdmin, isFalse);
      expect(access.canAccessPos, isTrue);
      expect(access.onlyWorkspace, AppWorkspace.pos);
    });

    test('does not treat POS till delegation as Tenant Admin access', () {
      final access = resolveWorkspaceAccess(const [
        'workspace.pos.access',
        'tenant.till.manage',
        'tenant.tills.manage',
        'pos.till.open',
      ]);

      expect(access.canAccessTenantAdmin, isFalse);
      expect(access.canAccessPos, isTrue);
    });

    test('grants both workspaces when both permission groups exist', () {
      final access = resolveWorkspaceAccess(const [
        'workspace.tenant_admin.access',
        'workspace.pos.access',
      ]);

      expect(access.hasMultiple, isTrue);
      expect(access.onlyWorkspace, isNull);
    });

    test('grants no workspace for unrelated permissions', () {
      final access = resolveWorkspaceAccess(const ['account.profile.edit']);

      expect(access.hasAny, isFalse);
    });

    test('does not infer workspace access from module permission prefixes', () {
      final access = resolveWorkspaceAccess(const [
        'tenant.users.manage',
        'tenant.tills.manage',
        'pos.home.view',
      ]);

      expect(access.hasAny, isFalse);
    });
  });
}
