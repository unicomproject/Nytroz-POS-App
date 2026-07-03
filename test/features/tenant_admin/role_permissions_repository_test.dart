import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/data/models/update_role_permissions_request_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/role_permissions/domain/entities/role_permissions.dart';

void main() {
  test('update request dto sends permissionCodes payload', () {
    const request = UpdateRolePermissionsRequestDto(
      permissionCodes: [
        'roles.permissions.view',
        'outlet.view',
      ],
    );

    expect(request.toJson(), {
      'permissionCodes': [
        'roles.permissions.view',
        'outlet.view',
      ],
    });
  });

  test('update request entity carries selected permission codes', () {
    const request = UpdateRolePermissionsRequest(
      permissionCodes: ['roles.permissions.view'],
    );

    expect(request.permissionCodes, ['roles.permissions.view']);
  });
}
