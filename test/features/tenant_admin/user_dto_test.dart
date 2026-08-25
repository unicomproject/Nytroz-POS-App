import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/users/data/mappers/tenant_user_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/users/data/models/tenant_user_dto.dart';

void main() {
  group('TenantUserListResultDto', () {
    test('parses tenant-admin users list API response', () {
      final dto = TenantUserListResultDto.fromJson({
        'items': [
          {
            'userId': '11111111-1111-1111-1111-111111111111',
            'fullName': 'Sarah Ahmed',
            'email': 'sarah@coffeecorner.com',
            'phoneNumber': '+44 7911 123456',
            'roleId': '22222222-2222-2222-2222-222222222222',
            'roleName': 'Store Manager',
            'roleDescription': 'Leads day-to-day outlet operations',
            'outletName': 'High Street Store',
            'outlets': [
              {
                'outletId': 'outlet-1',
                'outletName': 'High Street Store',
                'outletCode': 'HS-01',
                'status': 'ACTIVE',
              },
            ],
            'outletCount': 1,
            'status': 'ACTIVE',
            'lastActiveAt': '2026-06-22T10:00:00Z',
          },
        ],
        'page': 1,
        'pageSize': 10,
        'totalCount': 1,
      });

      expect(dto.totalCount, 1);
      expect(dto.items.single.fullName, 'Sarah Ahmed');
      expect(dto.items.single.email, 'sarah@coffeecorner.com');
      expect(dto.items.single.roleName, 'Store Manager');
      expect(dto.items.single.roleDescription,
          'Leads day-to-day outlet operations');
      expect(dto.items.single.outlets.single.name, 'High Street Store');
      expect(dto.items.single.outletCount, 1);
      expect(dto.items.single.status, 'ACTIVE');
      expect(dto.items.single.lastActiveAt, isNotNull);
    });

    test('falls back gracefully when optional fields are missing', () {
      final dto = TenantUserListResultDto.fromJson({
        'items': [
          {
            'userId': '11111111-1111-1111-1111-111111111111',
            'fullName': 'Sarah Ahmed',
            'email': 'sarah@coffeecorner.com',
            'roleName': 'Store Manager',
            'outletName': '',
            'status': 'INVITED',
          },
        ],
      });

      expect(dto.page, 1);
      expect(dto.pageSize, 5);
      expect(dto.totalCount, 1);
      expect(dto.items.single.phone, isNull);
      expect(dto.items.single.lastActiveAt, isNull);
    });
  });

  group('TenantUserCreateOptionsDto', () {
    test('parses roles, outlets, and grouped permissions', () {
      final dto = TenantUserCreateOptionsDto.fromJson({
        'roles': [
          {'roleId': 'role-1', 'roleName': 'Store Manager', 'roleCode': 'MGR'},
        ],
        'outlets': [
          {
            'outletId': 'outlet-1',
            'outletName': 'High Street Store',
            'outletCode': 'HS-01',
            'status': 'ACTIVE',
          },
        ],
        'permissionGroups': [
          {
            'groupName': 'Sales & Billing',
            'permissions': [
              {
                'permissionId': 'perm-1',
                'permissionCode': 'tenant.sales.view',
                'actionType': 'View Sales',
              },
            ],
          },
        ],
      });

      expect(dto.roles.single.name, 'Store Manager');
      expect(dto.outlets.single.name, 'High Street Store');
      expect(dto.permissionGroups.single.groupName, 'Sales & Billing');
      expect(dto.permissionGroups.single.permissions.single.code,
          'tenant.sales.view');
    });
  });

  group('TenantUserDetailDto', () {
    test('parses detail response including override permissions', () {
      final dto = TenantUserDetailDto.fromJson({
        'userId': 'user-1',
        'fullName': 'Sarah Ahmed',
        'email': 'sarah@coffeecorner.com',
        'phoneNumber': '+44 7911 123456',
        'roleId': 'role-1',
        'roleName': 'Store Manager',
        'roleDescription': 'Leads day-to-day outlet operations',
        'outlets': [
          {
            'outletId': 'outlet-1',
            'outletName': 'High Street Store',
            'outletCode': 'HS-01',
            'status': 'ACTIVE',
          },
        ],
        'status': 'ACTIVE',
        'outletCount': 1,
        'accessSummary': {
          'outletCount': 1,
          'moduleCount': 4,
          'permissionCount': 12,
        },
        'permissionOverrideEnabled': true,
        'overriddenPermissionIds': ['perm-1', 'perm-2'],
        'createdAt': '2026-01-05T08:00:00Z',
      });

      expect(dto.fullName, 'Sarah Ahmed');
      expect(dto.outlets.single.name, 'High Street Store');
      expect(dto.permissionOverrideEnabled, isTrue);
      expect(dto.overriddenPermissionIds, ['perm-1', 'perm-2']);
      expect(dto.createdAt, isNotNull);
      expect(dto.roleDescription, 'Leads day-to-day outlet operations');
      expect(dto.outletCount, 1);
      expect(dto.accessSummary?.moduleCount, 4);
    });
  });

  group('TenantUserMapper', () {
    test('maps list result DTO to domain entity', () {
      final dto = TenantUserListResultDto.fromJson({
        'items': [
          {
            'userId': 'user-1',
            'fullName': 'Sarah Ahmed',
            'email': 'sarah@coffeecorner.com',
            'roleName': 'Store Manager',
            'outletName': 'High Street Store',
            'status': 'ACTIVE',
          },
        ],
        'page': 1,
        'pageSize': 10,
        'totalCount': 1,
      });

      final result = TenantUserMapper.toListResult(dto);

      expect(result.items.single.fullName, 'Sarah Ahmed');
      expect(result.totalCount, 1);
      expect(result.totalPages, 1);
    });

    test('maps detail DTO to domain entity', () {
      final dto = TenantUserDetailDto.fromJson({
        'userId': 'user-1',
        'fullName': 'Sarah Ahmed',
        'email': 'sarah@coffeecorner.com',
        'roleName': 'Store Manager',
        'roleDescription': 'Leads day-to-day outlet operations',
        'outlets': [],
        'status': 'ACTIVE',
        'outletCount': 2,
        'accessSummary': {
          'outletCount': 2,
          'moduleCount': 4,
          'permissionCount': 12,
        },
        'permissionOverrideEnabled': false,
        'overriddenPermissionIds': [],
      });

      final detail = TenantUserMapper.toDetailEntity(dto);

      expect(detail.fullName, 'Sarah Ahmed');
      expect(detail.permissionOverrideEnabled, isFalse);
      expect(detail.outlets, isEmpty);
      expect(detail.roleDescription, 'Leads day-to-day outlet operations');
      expect(detail.outletCount, 2);
      expect(detail.accessSummary?.permissionCount, 12);
    });
  });
}
