import 'package:flutter_test/flutter_test.dart';

import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';

import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';

import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';

import 'package:nytroz_pos/features/tenant_admin/products/data/mappers/product_dashboard_mapper.dart';

import 'package:nytroz_pos/features/tenant_admin/products/data/models/product_dashboard_dto.dart';

import 'package:nytroz_pos/features/tenant_admin/products/presentation/dashboard/product_dashboard_formatters.dart';

import 'package:nytroz_pos/features/tenant_admin/products/presentation/dashboard/product_dashboard_navigation.dart';

import 'package:nytroz_pos/features/tenant_admin/products/presentation/dashboard/product_dashboard_providers.dart';

import 'package:nytroz_pos/features/tenant_admin/products/presentation/dashboard/product_dashboard_visibility.dart';

TenantAdminAccessChecker _accessFor({
  required Iterable<String> permissionCodes,
  int outletCount = 0,
}) {
  return TenantAdminAccessChecker(
    TenantAdminContext(
      tenantId: 'tenant-1',
      tenantName: 'SCS-TIX',
      userId: 'user-1',
      userDisplayName: 'Tenant Admin',
      roles: const [],
      roleNames: const ['Tenant Admin'],
      outletScope: [
        for (var index = 0; index < outletCount; index++)
          TenantAdminOutletScope(
            outletId: 'outlet-$index',
            outletName: 'Outlet $index',
            isDefault: index == 0,
          ),
      ],
      featureEntitlements: const [],
      permissions: [
        for (final code in permissionCodes)
          TenantAdminPermission(
            permissionCode: code,
            permissionName: code,
          ),
      ],
      runtimeFlags: const [],
    ),
  );
}

void main() {
  group('ProductDashboardVisibility', () {
    test('blocks page without dashboard permission', () {
      final visibility = ProductDashboardVisibility.resolve(
        access: _accessFor(permissionCodes: const []),
      );

      expect(visibility.showPage, isFalse);

      expect(visibility.showSummarySection, isFalse);

      expect(visibility.showStockValueCard, isFalse);

      expect(visibility.showStockMovementCard, isFalse);
    });

    test('shows total products only with tenant.products.view', () {
      final withProducts = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
            TenantAdminPermissionCodes.tenantProductsView,
          ],
        ),
      );

      final withoutProducts = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
            TenantAdminPermissionCodes.tenantStockView,
          ],
        ),
      );

      expect(
        withProducts.visibleSummaryMetrics,
        contains(ProductDashboardSummaryMetricKey.totalProducts),
      );

      expect(
        withoutProducts.visibleSummaryMetrics,
        isNot(contains(ProductDashboardSummaryMetricKey.totalProducts)),
      );
    });

    test('shows low and out of stock only with tenant.stock.view', () {
      final visibility = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
            TenantAdminPermissionCodes.tenantStockView,
          ],
        ),
      );

      expect(
        visibility.visibleSummaryMetrics,
        containsAll([
          ProductDashboardSummaryMetricKey.lowStock,
          ProductDashboardSummaryMetricKey.outOfStock,
          ProductDashboardSummaryMetricKey.stockAdded,
        ]),
      );
    });

    test('shows expiry alerts only with tenant.stock.expiry.view', () {
      final withExpiry = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
            TenantAdminPermissionCodes.tenantStockExpiryView,
          ],
        ),
      );

      final withoutExpiry = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
            TenantAdminPermissionCodes.tenantStockView,
          ],
        ),
      );

      expect(
        withExpiry.visibleSummaryMetrics,
        contains(ProductDashboardSummaryMetricKey.expiryAlerts),
      );

      expect(
        withoutExpiry.visibleSummaryMetrics,
        isNot(contains(ProductDashboardSummaryMetricKey.expiryAlerts)),
      );
    });

    test('shows fast moving only with tenant.reports.products.view', () {
      final withReports = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
            TenantAdminPermissionCodes.tenantReportsProductsView,
          ],
        ),
      );

      final withoutReports = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
            TenantAdminPermissionCodes.tenantStockView,
          ],
        ),
      );

      expect(
        withReports.visibleSummaryMetrics,
        contains(ProductDashboardSummaryMetricKey.fastMovingProducts),
      );

      expect(
        withoutReports.visibleSummaryMetrics,
        isNot(contains(ProductDashboardSummaryMetricKey.fastMovingProducts)),
      );
    });

    test('shows stock value card only with tenant.stock.value.view', () {
      final withValue = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
            TenantAdminPermissionCodes.tenantStockValueView,
          ],
        ),
      );

      final withoutValue = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
          ],
        ),
      );

      expect(withValue.showStockValueCard, isTrue);

      expect(withoutValue.showStockValueCard, isFalse);
    });

    test('shows stock movement card only with tenant.stock.movements.view', () {
      final withMovement = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
            TenantAdminPermissionCodes.tenantStockMovementsView,
          ],
        ),
      );

      final withoutMovement = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
          ],
        ),
      );

      expect(withMovement.showStockMovementCard, isTrue);

      expect(withoutMovement.showStockMovementCard, isFalse);
    });

    test('shows outlet filter only with outlet.view and multiple outlets', () {
      final visible = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
            TenantAdminPermissionCodes.outletView,
          ],
          outletCount: 2,
        ),
      );

      final hiddenSingleOutlet = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
            TenantAdminPermissionCodes.outletView,
          ],
          outletCount: 1,
        ),
      );

      final hiddenNoOutletPermission = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
          ],
          outletCount: 2,
        ),
      );

      expect(visible.showOutletFilter, isTrue);

      expect(hiddenSingleOutlet.showOutletFilter, isFalse);

      expect(hiddenNoOutletPermission.showOutletFilter, isFalse);
    });

    test('inventory.stock.view alias grants stock summary metrics', () {
      final visibility = ProductDashboardVisibility.resolve(
        access: _accessFor(
          permissionCodes: [
            TenantAdminPermissionCodes.tenantProductsDashboardView,
            'inventory.stock.view',
          ],
        ),
      );

      expect(
        visibility.visibleSummaryMetrics,
        contains(ProductDashboardSummaryMetricKey.lowStock),
      );
    });
  });

  group('ProductDashboardNavigation', () {
    test('KPI routes match specification', () {
      expect(
        ProductDashboardNavigation.routeFor(
          ProductDashboardSummaryMetricKey.lowStock,
        ),
        '/tenant-admin/stock/current?stockStatus=LOW_STOCK',
      );

      expect(
        ProductDashboardNavigation.routeFor(
          ProductDashboardSummaryMetricKey.fastMovingProducts,
        ),
        '/tenant-admin/reports/products?type=fast-moving',
      );
    });

    test('navigation requires destination permissions', () {
      final access = _accessFor(
        permissionCodes: [
          TenantAdminPermissionCodes.tenantProductsDashboardView,
          TenantAdminPermissionCodes.tenantProductsView,
        ],
      );

      expect(
        ProductDashboardNavigation.canNavigate(
          access,
          ProductDashboardSummaryMetricKey.totalProducts,
        ),
        isTrue,
      );

      expect(
        ProductDashboardNavigation.canNavigate(
          access,
          ProductDashboardSummaryMetricKey.lowStock,
        ),
        isFalse,
      );
    });
  });

  group('ProductDashboardFilter', () {
    test('today is default date range', () {
      const filter = ProductDashboardFilter();

      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      expect(filter.preset, ProductDashboardDatePreset.today);

      expect(filter.dateFrom, today);

      expect(filter.dateTo, today);
    });

    test('unchanged filters are equal', () {
      const first = ProductDashboardFilter();

      const second = ProductDashboardFilter();

      expect(first, second);
    });

    test('query includes outlet and formatted dates', () {
      const filter = ProductDashboardFilter(
        outletId: 'outlet-1',
        preset: ProductDashboardDatePreset.last7,
      );

      final query = filter.toQuery();

      expect(query.outletId, 'outlet-1');

      expect(query.dateFrom.isBefore(query.dateTo), isTrue);
    });
  });

  group('ProductDashboardDto', () {
    test('parses dashboard payload with nullable sections', () {
      final dto = ProductDashboardDto.fromJson({
        'lastUpdatedAt': '2026-07-10T10:30:00Z',
        'currencyCode': 'USD',
        'summary': {
          'totalProducts': {'value': 120, 'changePercent': 4.5},
          'lowStock': {'value': 8, 'changePercent': -2.0},
          'expiryAlerts': null,
        },
        'stockValue': {
          'currentValue': 250000,
          'changePercent': 3.2,
          'trend': [
            {'date': '2026-07-08', 'value': 200000},
            {'date': '2026-07-09', 'value': 225000},
          ],
        },
        'stockMovement': {
          'totalCount': 42,
          'items': [
            {'type': 'stock_in', 'count': 20, 'percentage': 47.6},
            {'type': 'stock_out', 'count': 22, 'percentage': 52.4},
          ],
        },
      });

      expect(dto.currencyCode, 'USD');

      expect(dto.summary?.totalProducts?.value, 120);

      expect(dto.summary?.expiryAlerts, isNull);

      expect(dto.stockValue?.trend, hasLength(2));

      expect(dto.stockMovement?.items.first.type, 'stock_in');
    });

    test('mapper converts dto to entity', () {
      final entity = ProductDashboardMapper.toEntity(
        ProductDashboardDto.fromJson({
          'currencyCode': 'EUR',
          'summary': {
            'fastMovingProducts': {'value': 5, 'changePercent': 1.1},
          },
          'stockMovement': {
            'totalCount': 10,
            'items': [
              {'type': 'transfer', 'count': 10, 'percentage': 100},
            ],
          },
        }),
      );

      expect(entity.currencyCode, 'EUR');

      expect(entity.summary?.fastMovingProducts?.value, 5);

      expect(entity.stockMovement?.items.first.label, 'Transfers');
    });
  });

  group('ProductDashboardFormatters', () {
    test('formats currency from backend code without hardcoded default', () {
      expect(
        formatProductDashboardCurrency(1200, currencyCode: 'JPY'),
        'JPY 1200',
      );

      expect(
        formatProductDashboardCurrency(1200, currencyCode: 'USD'),
        '\$1200',
      );
    });

    test('formats trend text with direction labels', () {
      expect(
        formatProductDashboardTrend(6.2).label,
        '6.2% higher than previous period',
      );

      expect(
        formatProductDashboardTrend(-12.1).label,
        '12.1% lower than previous period',
      );

      expect(
        formatProductDashboardTrend(0).label,
        'No change from previous period',
      );
    });
  });

  group('TenantAdminAccessChecker product dashboard', () {
    test('canFetchProductDashboard requires dashboard permission', () {
      final denied = _accessFor(permissionCodes: const []);

      final allowed = _accessFor(
        permissionCodes: [
          TenantAdminPermissionCodes.tenantProductsDashboardView,
        ],
      );

      expect(denied.canFetchProductDashboard(), isFalse);

      expect(allowed.canFetchProductDashboard(), isTrue);
    });

    test('add product permission is separate from dashboard view', () {
      final access = _accessFor(
        permissionCodes: [
          TenantAdminPermissionCodes.tenantProductsDashboardView,
        ],
      );

      expect(access.canCreateProduct(), isFalse);
    });

    test('stock movement legend navigation permissions', () {
      final access = _accessFor(
        permissionCodes: [
          TenantAdminPermissionCodes.tenantStockIn,
          TenantAdminPermissionCodes.tenantStockAdjustmentsView,
        ],
      );

      expect(
        ProductDashboardNavigation.canNavigateMovement(access, 'stock_in'),
        isTrue,
      );

      expect(
        ProductDashboardNavigation.canNavigateMovement(access, 'adjustment'),
        isTrue,
      );

      expect(
        ProductDashboardNavigation.canNavigateMovement(access, 'transfer'),
        isFalse,
      );
    });
  });
}
