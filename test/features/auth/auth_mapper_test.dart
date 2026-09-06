import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/auth/data/mappers/auth_mapper.dart';

void main() {
  group('authSessionFromJson', () {
    test('maps backend tenant login permissionCodes into AuthSession', () {
      final session = authSessionFromJson({
        'data': {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'user': {
            'id': 'cashier-001',
            'fullName': 'Cashier 001',
          },
          'permissionCodes': const [
            PosPermissionCodes.viewNewSale,
            PosPermissionCodes.viewOrders,
            PosPermissionCodes.viewCashDrawer,
          ],
        },
      });

      expect(session.permissionCodes, contains(PosPermissionCodes.viewNewSale));
      expect(session.permissionCodes, contains(PosPermissionCodes.viewOrders));
      expect(
        session.permissionCodes,
        contains(PosPermissionCodes.viewCashDrawer),
      );
    });

    test('maps PascalCase and object-shaped permissions defensively', () {
      final session = authSessionFromJson({
        'Data': {
          'AccessToken': 'access-token',
          'User': {
            'Id': 'cashier-001',
            'FullName': 'Cashier 001',
          },
          'Permissions': const [
            {'PermissionCode': PosPermissionCodes.viewNewSale},
            {'code': PosPermissionCodes.viewOrders},
            PosPermissionCodes.viewCashDrawer,
          ],
        },
      });

      expect(session.userId, 'cashier-001');
      expect(session.userDisplayName, 'Cashier 001');
      expect(
        session.permissionCodes,
        containsAll(
          const [
            PosPermissionCodes.viewNewSale,
            PosPermissionCodes.viewOrders,
            PosPermissionCodes.viewCashDrawer,
          ],
        ),
      );
    });

    test('prefers effectivePermissionCodes over permissions when both present', () {
      final session = authSessionFromJson({
        'data': {
          'accessToken': 'access-token',
          'user': {
            'id': 'cashier-001',
            'fullName': 'Cashier 001',
          },
          'effectivePermissionCodes': const [
            PosPermissionCodes.viewNewSale,
          ],
          'permissions': const [
            PosPermissionCodes.viewOrders,
            PosPermissionCodes.viewCashDrawer,
          ],
        },
      });

      expect(session.permissionCodes, [PosPermissionCodes.viewNewSale]);
      expect(
        session.permissionCodes,
        isNot(contains(PosPermissionCodes.viewOrders)),
      );
    });

    test('absent permission membership is false and does not invent grants', () {
      final session = authSessionFromJson({
        'data': {
          'accessToken': 'access-token',
          'user': {
            'id': 'cashier-001',
            'fullName': 'Cashier 001',
          },
          'permissions': const [
            PosPermissionCodes.viewNewSale,
          ],
        },
      });

      expect(session.hasPermission(PosPermissionCodes.viewNewSale), isTrue);
      expect(session.hasPermission(PosPermissionCodes.viewCashDrawer), isFalse);
      expect(session.hasPermission('pre_auth.login.email.input'), isFalse);
    });
  });
}
