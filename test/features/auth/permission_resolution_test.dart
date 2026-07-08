import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/domain/utils/jwt_permissions.dart';

void main() {
  group('readJwtPermissionCodes', () {
    test('reads permission codes from JWT permissions claim', () {
      final payload = base64Url.encode(
        utf8.encode(
          '{"permissions":["tenant.dashboard.view","pos.home.view"],"exp":1893456000}',
        ),
      );
      final token = 'header.$payload.signature';

      expect(
        readJwtPermissionCodes(token),
        ['tenant.dashboard.view', 'pos.home.view'],
      );
    });
  });

  group('POS legacy permission seeds', () {
    test('pos.sale.create grants home and new sale access', () {
      const granted = {'pos.sale.create'};

      expect(PosPermissionAccess.canViewHome(granted), isTrue);
      expect(PosPermissionAccess.canAccessNewSale(granted), isTrue);
    });
  });

  group('AuthSession dashboard routing', () {
    test('tenant.dashboard.view enables tenant admin dashboard access', () {
      const session = AuthSession(
        accessToken: 'token',
        userId: 'tenant-admin-1',
        userDisplayName: 'Tenant Admin',
        permissionCodes: ['tenant.dashboard.view'],
      );

      expect(session.canAccessTenantAdminDashboard, isTrue);
    });
  });
}
