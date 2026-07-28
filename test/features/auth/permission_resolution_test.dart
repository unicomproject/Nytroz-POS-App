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
    test('sales.create grants new sale access only', () {
      const granted = {'sales.create'};

      expect(PosPermissionAccess.canViewHome(granted), isFalse);
      expect(PosPermissionAccess.canAccessNewSale(granted), isTrue);
    });

    test('legacy pos.sale.create grants New Sale', () {
      const granted = {'pos.sale.create'};
      expect(PosPermissionAccess.canAccessNewSale(granted), isTrue);
    });

    test('pos.home.view and pos.dashboard.view grant home access', () {
      expect(
        PosPermissionAccess.canViewHome(const {'pos.home.view'}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewHome(const {'pos.dashboard.view'}),
        isTrue,
      );
    });

    test('cash drawer view and manage are separated', () {
      expect(
        PosPermissionAccess.canViewCashDrawer(const {'cash_drawer.view'}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewCashDrawer(const {'cash_drawer.manage'}),
        isFalse,
      );
      expect(
        PosPermissionAccess.canCreateCashDrawerMovement(
          const {'cash_drawer.manage'},
        ),
        isTrue,
      );
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

    test('tenant.context.view alone does not select dashboard access', () {
      const session = AuthSession(
        accessToken: 'token',
        userId: 'tenant-admin-context-1',
        userDisplayName: 'Tenant Admin',
        permissionCodes: ['tenant.context.view'],
      );

      expect(session.canAccessTenantAdminDashboard, isFalse);
    });
  });

  group('AuthSession POS till access', () {
    test('canOpenPosTill is true when pos.till.open exists', () {
      const session = AuthSession(
        accessToken: 'token',
        userId: 'cashier-1',
        userDisplayName: 'Cashier',
        permissionCodes: ['pos.till.open'],
      );

      expect(session.canOpenPosTill, isTrue);
    });

    test('canOpenPosTill is false when pos.till.open is absent', () {
      const session = AuthSession(
        accessToken: 'token',
        userId: 'cashier-1',
        userDisplayName: 'Cashier',
        permissionCodes: ['pos.home.view'],
      );

      expect(session.canOpenPosTill, isFalse);
    });
  });
}
