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
}
