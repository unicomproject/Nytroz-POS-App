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
  });
}
