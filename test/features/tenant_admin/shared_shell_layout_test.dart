import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/pos_shell/application/state/pos_home_dashboard_state.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/common/pos_top_bar.dart';
import 'package:nytroz_pos/features/tenant_admin/data/catalog/tenant_admin_menu_catalog.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/layout/tenant_admin_footer_navigation.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/layout/tenant_admin_header.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/layout/tenant_admin_shared_shell.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/layout/tenant_admin_sidebar.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_context_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_menu_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_sidebar_provider.dart';
import 'package:nytroz_pos/features/till/application/usecases/open_till.dart';
import 'package:nytroz_pos/features/till/data/datasources/till_session_storage.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_hardware_readiness.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/repositories/till_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_monitoring.dart';
import 'package:nytroz_pos/features/till/domain/entities/open_till.dart';
import 'package:nytroz_pos/features/till/domain/repositories/till_repository.dart'
    as till_repo;
import 'package:nytroz_pos/features/till/presentation/providers/till_provider.dart';

TenantAdminAccessChecker _fullAccess() {
  return TenantAdminAccessChecker(
    TenantAdminContext(
      tenantId: 'tenant-1',
      tenantName: 'OneVerz',
      tenantLogoUrl: 'https://example.test/tenant-logo.png',
      userId: 'user-1',
      userDisplayName: 'Admin',
      roles: const [],
      roleNames: const ['Tenant Admin'],
      outletScope: const [],
      featureEntitlements: const [
        TenantAdminFeatureEntitlement(
          featureCode: TenantAdminFeatureCodes.dashboard,
          featureName: 'Dashboard',
          enabled: true,
        ),
        TenantAdminFeatureEntitlement(
          featureCode: TenantAdminFeatureCodes.outletManagement,
          featureName: 'Outlets',
          enabled: true,
        ),
        TenantAdminFeatureEntitlement(
          featureCode: TenantAdminFeatureCodes.tillManagement,
          featureName: 'Tills',
          enabled: true,
        ),
        TenantAdminFeatureEntitlement(
          featureCode: TenantAdminFeatureCodes.staffManagement,
          featureName: 'Users',
          enabled: true,
        ),
        TenantAdminFeatureEntitlement(
          featureCode: TenantAdminFeatureCodes.rolePermission,
          featureName: 'Roles',
          enabled: true,
        ),
        TenantAdminFeatureEntitlement(
          featureCode: TenantAdminFeatureCodes.productManagement,
          featureName: 'Products',
          enabled: true,
        ),
        TenantAdminFeatureEntitlement(
          featureCode: TenantAdminFeatureCodes.inventoryManagement,
          featureName: 'Inventory',
          enabled: true,
        ),
        TenantAdminFeatureEntitlement(
          featureCode: TenantAdminFeatureCodes.tenantSettings,
          featureName: 'Settings',
          enabled: true,
        ),
      ],
      permissions: [
        for (final code in [
          TenantAdminPermissionCodes.tenantDashboardView,
          TenantAdminPermissionCodes.outletView,
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.userView,
          TenantAdminPermissionCodes.rolesPermissionsView,
          TenantAdminPermissionCodes.roleView,
          TenantAdminPermissionCodes.permissionView,
          TenantAdminPermissionCodes.tenantProductsView,
          TenantAdminPermissionCodes.tenantProductsCreate,
          TenantAdminPermissionCodes.tenantCategoriesView,
          TenantAdminPermissionCodes.tenantBrandsView,
          TenantAdminPermissionCodes.tenantStockView,
          TenantAdminPermissionCodes.tenantProductImport,
          TenantAdminPermissionCodes.tenantHardwareView,
          TenantAdminPermissionCodes.tenantSettingsView,
        ])
          TenantAdminPermission(permissionCode: code, permissionName: code),
      ],
      runtimeFlags: const [],
    ),
  );
}

AuthSession _session() {
  return const AuthSession(
    accessToken: 'token',
    userId: 'user-1',
    userDisplayName: 'Admin',
    permissionCodes: [
      'pos.home.view',
      'pos.sale.create',
      'pos.customers.view',
    ],
  );
}

class _TestAuthSessionStorage extends AuthSessionStorage {
  _TestAuthSessionStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> save(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}

class _PresetAuthSessionNotifier extends AuthSessionNotifier {
  _PresetAuthSessionNotifier(AuthSession session)
      : super(_TestAuthSessionStorage()) {
    state = session;
  }
}

class _TestTillSessionStorage extends TillSessionStorage {
  _TestTillSessionStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));

  @override
  Future<TillSession?> read() async => null;

  @override
  Future<void> save(TillSession session) async {}

  @override
  Future<void> clear() async {}
}

class _FakeTillRepository implements TillRepository, till_repo.TillRepository {
  @override
  Future<CreatedTill> createTill(TillFormData form) async {
    throw UnimplementedError();
  }

  @override
  Future<CreatedTill> createTillSetup(AddTillFormData form) async {
    throw UnimplementedError();
  }

  @override
  Future<TillSession> openTill(OpenTillForm form) {
    throw UnimplementedError();
  }

  @override
  Future<TillSession?> getCurrentSession(OpenTillForm form) async => null;

  @override
  Future<ClosedTillSession> closeTill(CloseTillForm form) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTill(String id) async {}

  @override
  Future<TillCreateOptions> getCreateOptions({String? outletId}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<OutletOption>> getOutletOptions() async {
    return const [];
  }

  @override
  Future<TillDetail> getTillById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<TillDetail> updateTill(String id, TillFormData form) async {
    throw UnimplementedError();
  }

  @override
  Future<TillMonitoringResult> getTills({required TillListQuery query}) async {
    throw UnimplementedError();
  }

  @override
  Future<TillMonitoringSummary> getTillSummary() async {
    throw UnimplementedError();
  }

  @override
  Future<TillHardwareReadiness> getTillHardwareReadiness(String id) async {
    throw UnimplementedError();
  }
}

class _PresetTillController extends TillController {
  _PresetTillController()
      : super(
          OpenTill(_FakeTillRepository()),
          _TestTillSessionStorage(),
        );
}

List<Override> _shellOverrides(TenantAdminAccessChecker access) {
  return [
    authSessionProvider.overrideWith(
      (ref) => _PresetAuthSessionNotifier(_session()),
    ),
    tillSessionStorageProvider.overrideWithValue(_TestTillSessionStorage()),
    openTillProvider.overrideWithValue(OpenTill(_FakeTillRepository())),
    tillProvider.overrideWith((ref) => _PresetTillController()),
    posHomeDashboardProvider.overrideWith(
      (ref) => const PosHomeDashboardState(
        actions: [],
        fallbackUserDisplayName: 'Admin',
        businessDisplayName: 'Tenant Brand',
        businessLogoUrl: 'https://example.test/tenant-logo.png',
        outletName: 'Main Outlet',
        tillLabel: 'Front Till 01',
        tillStatusLabel: 'Closed',
        isTillOpen: false,
        statusMessage: 'Session Closed',
      ),
    ),
    tenantAdminAccessCheckerProvider.overrideWith((ref) async => access),
    tenantAdminContextProvider.overrideWith((ref) async => access.context),
    tenantAdminMenuProvider.overrideWith((ref) async {
      return tenantAdminMenuCatalog
          .where(access.canAccessMenuItem)
          .toList(growable: false)
        ..sort((a, b) => a.order.compareTo(b.order));
    }),
    productsSidebarManualExpandedProvider.overrideWith((ref) => true),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tenantAdminMenuCatalog approved order', () {
    test('matches locked sidebar order and settings last', () {
      final labels = tenantAdminMenuCatalog
          .map((item) => item.label)
          .toList(growable: false);

      expect(labels, [
        'Dashboard',
        'Outlets',
        'Tills',
        'Users',
        'Online Store',
        'Roles & Access',
        'Hardware',
        'Inventory',
        'Products',
        'Reports',
        'Settings',
      ]);
      expect(tenantAdminMenuCatalog.last.key, 'settings');
      expect(
        tenantAdminMenuCatalog
            .firstWhere((item) => item.key == 'online-store')
            .isRouteAvailable,
        isFalse,
      );
    });
  });

  group('TenantAdminSharedShell', () {
    testWidgets('renders header and sidebar without footer on desktop',
        (tester) async {
      final access = _fullAccess();
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _shellOverrides(access),
          child: const MaterialApp(
            home: TenantAdminSharedShell(
              currentRoute: '/tenant-admin/dashboard',
              child: Text('Dashboard body'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PosTopBar), findsOneWidget);
      expect(find.byType(TenantAdminHeader), findsNothing);
      expect(find.byType(TenantAdminSidebar), findsOneWidget);
      expect(find.byType(TenantAdminFooterNavigation), findsNothing);
      expect(find.text('Dashboard body'), findsOneWidget);
      expect(find.text('Online Store'), findsOneWidget);
      expect(find.text('Hardware'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expands products children with brands active path',
        (tester) async {
      final access = _fullAccess();
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _shellOverrides(access),
          child: const MaterialApp(
            home: TenantAdminSharedShell(
              currentRoute: '/tenant-admin/brands',
              child: Text('Brands body'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Product'), findsOneWidget);
      expect(find.text('Categories & Subcategories'), findsOneWidget);
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('Product List'), findsNothing);
      expect(find.text('Import'), findsNothing);

      final menuLabels = tenantAdminMenuCatalog
          .where(access.canAccessMenuItem)
          .map((e) => e.label)
          .toList();
      expect(menuLabels.last, 'Settings');
    });

    testWidgets('disabled online store shows unavailable snackbar',
        (tester) async {
      final access = _fullAccess();
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _shellOverrides(access),
          child: const MaterialApp(
            home: TenantAdminSharedShell(
              currentRoute: '/tenant-admin/dashboard',
              child: Text('body'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Online Store'));
      await tester.tap(find.text('Online Store'));
      await tester.pumpAndSettle();
      expect(find.text('Online Store is not available yet.'), findsOneWidget);
    });

    testWidgets('mobile uses drawer without footer', (tester) async {
      final access = _fullAccess();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _shellOverrides(access),
          child: const MaterialApp(
            home: TenantAdminSharedShell(
              currentRoute: '/tenant-admin/settings',
              child: Text('Settings body'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PosTopBar), findsOneWidget);
      expect(find.byType(TenantAdminHeader), findsNothing);
      expect(find.byType(TenantAdminSidebar), findsNothing);
      expect(find.byType(TenantAdminFooterNavigation), findsNothing);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet layout shows sidebar without overflow', (tester) async {
      final access = _fullAccess();
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _shellOverrides(access),
          child: const MaterialApp(
            home: TenantAdminSharedShell(
              currentRoute: '/tenant-admin/products',
              child: Text('Products body'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TenantAdminSidebar), findsOneWidget);
      expect(find.byType(TenantAdminFooterNavigation), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Footer settings active', () {
    test('marks catalog routes as settings area', () {
      expect(isTenantAdminSettingsAreaPath('/tenant-admin/settings'), isTrue);
      expect(isTenantAdminSettingsAreaPath('/tenant-admin/brands'), isTrue);
      expect(isTenantAdminSettingsAreaPath('/tenant-admin/products'), isFalse);
      expect(isTenantAdminSettingsAreaPath('/tenant-admin/dashboard'), isFalse);
    });
  });
}
