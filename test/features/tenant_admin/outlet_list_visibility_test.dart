import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/config/outlet_table_column_configs.dart';

void main() {
  group('OutletListVisibility', () {
    test('blocks outlet page when outlet.view is missing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      final visibility = OutletListVisibility.resolve(access: access);

      expect(visibility.showPage, isFalse);
      expect(visibility.showList, isFalse);
    });

    test('renders list when outlet.view exists', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      final visibility = OutletListVisibility.resolve(access: access);

      expect(visibility.showPage, isTrue);
      expect(visibility.showList, isTrue);
      expect(visibility.showAddOutlet, isFalse);
      expect(visibility.showSummarySection, isFalse);
    });

    test('shows Add outlet button only with outlet.create', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.outletView,
          TenantAdminPermissionCodes.outletCreate,
        ],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      final visibility = OutletListVisibility.resolve(access: access);

      expect(visibility.showAddOutlet, isTrue);
    });

    test('shows summary cards only with outlet.summary.view', () {
      final withSummary = _checker(
        permissions: [
          TenantAdminPermissionCodes.outletView,
          TenantAdminPermissionCodes.outletSummaryView,
        ],
        features: [TenantAdminFeatureCodes.outletManagement],
      );
      final withoutSummary = _checker(
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      expect(
        OutletListVisibility.resolve(access: withSummary).showSummarySection,
        isTrue,
      );
      expect(
        OutletListVisibility.resolve(access: withoutSummary).showSummarySection,
        isFalse,
      );
    });

    test('shows city column only with outlet.location.view', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.outletView,
          TenantAdminPermissionCodes.outletLocationView,
        ],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      final visibility = OutletListVisibility.resolve(access: access);

      expect(
        visibility.visibleColumns.any(
          (column) => column.columnId == OutletTableColumnId.city,
        ),
        isTrue,
      );
    });

    test('hides city column without outlet.location.view', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      final visibility = OutletListVisibility.resolve(access: access);

      expect(
        visibility.visibleColumns.any(
          (column) => column.columnId == OutletTableColumnId.city,
        ),
        isFalse,
      );
    });

    test('shows row actions only with matching action permissions', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.outletView,
          TenantAdminPermissionCodes.outletUpdate,
          TenantAdminPermissionCodes.outletDelete,
        ],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      final visibility = OutletListVisibility.resolve(access: access);

      expect(visibility.showActionsColumn, isTrue);
      expect(visibility.visibleRowActions.length, 2);
      expect(
        visibility.visibleRowActions.any((action) => action.id == 'edit'),
        isTrue,
      );
      expect(
        visibility.visibleRowActions.any((action) => action.id == 'delete'),
        isTrue,
      );
      expect(
        visibility.visibleRowActions.any((action) => action.id == 'view_details'),
        isFalse,
      );
    });

    test('hides actions column when no row action permission exists', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      final visibility = OutletListVisibility.resolve(access: access);

      expect(visibility.showActionsColumn, isFalse);
      expect(visibility.visibleRowActions, isEmpty);
      expect(
        visibility.visibleColumns.any(
          (column) => column.columnId == OutletTableColumnId.actions,
        ),
        isFalse,
      );
    });

    test('mobile card hides restricted fields', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      final visibility = OutletListVisibility.resolve(access: access);

      expect(visibility.showMobileLocation, isFalse);
      expect(visibility.showMobileSales, isFalse);
      expect(visibility.showMobileTillSummary, isFalse);
      expect(visibility.showMobileStaffSummary, isFalse);
      expect(visibility.showMobileActionsMenu, isFalse);
    });

    test('does not crash when permission list is empty', () {
      final access = _checker(
        permissions: const [],
        features: const [],
      );

      final visibility = OutletListVisibility.resolve(access: access);

      expect(visibility.showPage, isFalse);
      expect(visibility.visibleSummaryCards, isEmpty);
      expect(visibility.visibleColumns, isEmpty);
    });
  });
}

TenantAdminAccessChecker _checker({
  required List<String> permissions,
  required List<String> features,
}) {
  return TenantAdminAccessChecker(
    TenantAdminContext(
      tenantId: 'tenant-test',
      tenantName: 'Coffee Corner Ltd',
      userId: 'user-test',
      userDisplayName: 'Sarah Ahmed',
      roleNames: ['Owner'],
      outletScope: const [
        TenantAdminOutletScope(
          outletId: 'outlet-1',
          outletName: 'High Street Store',
          isDefault: true,
        ),
      ],
      featureEntitlements: [
        for (final featureCode in features)
          TenantAdminFeatureEntitlement(
            featureCode: featureCode,
            featureName: featureCode,
            enabled: true,
          ),
      ],
      permissions: [
        for (final permissionCode in permissions)
          TenantAdminPermission(
            permissionCode: permissionCode,
            permissionName: permissionCode,
          ),
      ],
      runtimeFlags: [
        for (final featureCode in features)
          TenantAdminRuntimeFlag(featureCode: featureCode, enabled: true),
      ],
    ),
  );
}
