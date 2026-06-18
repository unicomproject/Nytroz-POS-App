import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/data/models/tenant_admin_context_dto.dart';

void main() {
  group('TenantAdminContextDto backend parsing', () {
    test('fromApiJson maps backend context payload into app dto', () {
      final dto = TenantAdminContextDto.fromApiJson({
        'success': true,
        'data': {
          'tenant': {
            'id': '11111111-1111-1111-1111-111111111111',
            'code': 'TENANT001',
            'name': 'Coffee Corner Ltd',
            'status': 'active',
          },
          'user': {
            'id': '22222222-2222-2222-2222-222222222222',
            'fullName': 'Tenant Admin',
            'email': 'tenant.admin@nytroz.local',
            'status': 'active',
          },
          'roles': [
            {'id': '33333333-3333-3333-3333-333333333333', 'name': 'Tenant Admin'},
          ],
          'features': ['dashboard', 'outlet_management', 'sales'],
          'permissions': ['tenant.context.view', 'dashboard.view', 'outlets.view'],
          'runtimeFlags': ['tenant_admin_dashboard_enabled'],
          'outlets': [
            {
              'id': '44444444-4444-4444-4444-444444444444',
              'name': 'Main Outlet',
              'code': 'OUTLET-001',
              'status': 'active',
            },
          ],
          'subscription': {
            'planName': 'Professional',
            'status': 'active',
            'nextBillingDate': '2026-07-12',
          },
        },
      });

      expect(dto.tenantName, 'Coffee Corner Ltd');
      expect(dto.userDisplayName, 'Tenant Admin');
      expect(dto.roleNames, ['Tenant Admin']);
      expect(
        dto.featureEntitlements.map((item) => item.featureCode),
        [
          TenantAdminFeatureCodes.dashboard,
          TenantAdminFeatureCodes.outletManagement,
          TenantAdminFeatureCodes.sales,
        ],
      );
      expect(
        dto.permissions.map((item) => item.permissionCode),
        ['tenant.context.view', 'dashboard.view', 'outlets.view'],
      );
      expect(dto.runtimeFlags.first.featureCode, 'tenant_admin_dashboard_enabled');
      expect(dto.outletScope.first.outletName, 'Main Outlet');
      expect(dto.subscriptionStatus, 'active');
    });
  });
}
