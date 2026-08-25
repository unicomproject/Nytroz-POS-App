//new
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/tenant_admin_access_codes.dart';
import 'domain/entities/tenant_admin_menu_item.dart';
import 'domain/services/tenant_admin_access_checker.dart';
import 'role_permissions/presentation/screens/role_permissions_screen.dart';
import 'presentation/layout/tenant_admin_shared_shell.dart';
import 'dashboard/presentation/screens/tenant_dashboard_screen.dart';
import 'outlets/presentation/screens/add_outlet_screen.dart';
import 'outlets/presentation/screens/edit_outlet_screen.dart';
import 'outlets/presentation/screens/outlet_details_screen.dart';
import 'outlets/presentation/screens/outlet_list_screen.dart';
import 'role_permissions/presentation/screens/create_custom_role_screen.dart';
import 'role_permissions/presentation/screens/edit_role_screen.dart';
import 'role_permissions/presentation/screens/role_setup_step1_role_screen.dart';
import 'role_permissions/presentation/screens/role_setup_step2_modules_screen.dart';
import 'role_permissions/presentation/screens/role_setup_step3_permissions_screen.dart';
import 'role_permissions/presentation/screens/role_setup_step4_assignments_screen.dart';
import 'role_permissions/presentation/screens/role_setup_step5_review_screen.dart';
import 'role_permissions/presentation/screens/roles_screen.dart';
import 'tills/presentation/screens/add_till_screen.dart';
import 'tills/presentation/screens/edit_till_screen.dart';
import 'tills/presentation/screens/till_details_screen.dart';
import 'tills/presentation/screens/till_monitoring_screen.dart';
import 'hardware/presentation/screens/hardware_list_screen.dart';
import 'hardware/presentation/screens/add_hardware_screen.dart';
import 'hardware/presentation/screens/hardware_detail_screen.dart';
import 'users/presentation/screens/add_edit_user_screen.dart';
import 'users/presentation/screens/user_list_screen.dart';
import 'products/presentation/dashboard/product_dashboard_page.dart';
import 'products/presentation/navigation/products_coming_soon_screen.dart';
import 'products/presentation/navigation/products_route_guard.dart';
import 'products/presentation/navigation/products_sidebar_routes.dart';
import 'inventory/presentation/opening_stock/screens/opening_stock_wizard_screen.dart';
import 'products/presentation/screens/add_product_screen.dart';
import 'products/presentation/screens/product_detail_screen.dart';
import 'products/presentation/screens/product_list_screen.dart';
import 'products/presentation/screens/popular_products_curation_screen.dart';
import 'brands/presentation/screens/brand_list_screen.dart';
import 'pricing_tax/tax_management/presentation/tax_management_page.dart';
import 'inventory/presentation/navigation/inventory_routes.dart';
import 'inventory/presentation/dashboard/pages/inventory_dashboard_page.dart';
import 'inventory/presentation/current_stock/screens/current_stock_screen.dart';
import 'inventory/presentation/current_stock/screens/product_stock_detail_screen.dart';
import 'inventory/presentation/receiving/receiving_flow.dart';
import 'inventory/presentation/adjustment/adjustment_flow.dart';
import 'inventory/presentation/channel_allocation/channel_allocation_flow.dart';
import 'inventory/presentation/serials/serial_registry_screen.dart';
import 'reports/presentation/screens/outlet_report_screen.dart';
import 'reports/presentation/screens/reports_dashboard_screen.dart';
import 'reports/presentation/screens/sales_report_screen.dart';
import 'reports/presentation/screens/sales_transaction_detail_screen.dart';
import 'reports/presentation/screens/stock_report_screen.dart';
import '../auth/presentation/providers/session_provider.dart';
import 'presentation/providers/tenant_admin_access_provider.dart';
import 'presentation/providers/tenant_admin_context_provider.dart';
import 'presentation/providers/tenant_admin_menu_provider.dart';
import 'presentation/providers/tenant_admin_navigation_provider.dart';
import 'presentation/routing/tenant_admin_route_definition.dart';
import 'presentation/screens/tenant_admin_error_screen.dart';
import 'presentation/screens/tenant_admin_forbidden_screen.dart';
import 'presentation/screens/tenant_admin_loading_screen.dart';
import 'presentation/screens/tenant_admin_placeholder_screen.dart';
import 'login_branding/presentation/screens/tenant_login_branding_screen.dart';
import 'online_store/presentation/screens/online_store_setup_screen.dart';

List<RouteBase> tenantAdminRoutes(Ref ref) {
  return [
    ShellRoute(
      builder: (context, state, child) {
        return TenantAdminLayout(
          currentPath: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/tenant-admin',
          redirect: (context, state) {
            final session = ref.read(authSessionProvider);
            if (session == null || !session.isAuthenticated) {
              return '/tenant-login';
            }

            final contextState = ref.read(tenantAdminContextProvider);
            final menuState = ref.read(tenantAdminMenuProvider);

            if (contextState.isLoading || menuState.isLoading) {
              return '/tenant-admin/dashboard';
            }

            if (contextState.hasError || menuState.hasError) {
              return '/tenant-admin/dashboard';
            }

            final firstRoute = ref.read(tenantAdminFirstPermittedRouteProvider);
            if (firstRoute == null) {
              return '/tenant-admin/no-access';
            }

            return firstRoute;
          },
        ),
        GoRoute(
          path: '/tenant-admin/no-access',
          builder: (context, state) => const TenantAdminForbiddenScreen(),
        ),
        GoRoute(
          path: '/tenant-admin/roles-access',
          redirect: (context, state) => '/tenant-admin/roles',
        ),
        GoRoute(
          path: '/tenant-admin/roles-permissions',
          redirect: (context, state) => '/tenant-admin/roles',
        ),
        // stockRoot is handled dynamically for access control, but we add a redirect
        // just in case it's navigated to directly.
        GoRoute(
          path: InventoryRoutes.stockRoot,
          redirect: (context, state) => InventoryRoutes.dashboard,
        ),
        GoRoute(
          path: InventoryRoutes.inventoryRoot,
          redirect: (context, state) => InventoryRoutes.dashboard,
        ),
        GoRoute(
          path: '/tenant-admin/products/import',
          redirect: (context, state) => '/tenant-admin/products',
        ),
        GoRoute(
          path: '/tenant-admin/products/local-draft/:localDraftId',
          builder: (context, state) {
            final localDraftId = state.pathParameters['localDraftId'];
            return AddProductScreen(resumeLocalDraftId: localDraftId);
          },
        ),
        GoRoute(
          path: '/tenant-admin/products/draft/:id',
          builder: (context, state) {
            final draftId = state.pathParameters['id'];
            return AddProductScreen(resumeProductId: draftId);
          },
        ),
        ...tenantAdminRouteDefinitions.map(
          (definition) => _tenantAdminModuleRoute(ref, definition),
        ),
      ],
    ),
  ];
}

GoRoute _tenantAdminModuleRoute(
  Ref ref,
  TenantAdminRouteDefinition definition,
) {
  return GoRoute(
    path: definition.path,
    redirect: (context, state) =>
        _tenantAdminAccessRedirect(ref, definition, state.uri.path),
    builder: (context, state) {
      return _TenantAdminGuardedScreen(
        definition: definition,
        child: _screenFor(definition, state),
      );
    },
  );
}

String? _tenantAdminAccessRedirect(
  Ref ref,
  TenantAdminRouteDefinition definition,
  String currentPath,
) {
  if (currentPath != definition.path) {
    return null;
  }

  final menuState = ref.read(tenantAdminMenuProvider);
  final accessState = ref.read(tenantAdminAccessCheckerProvider);

  if (!menuState.hasValue || !accessState.hasValue) {
    return null;
  }

  if (_canAccessRoute(
    menuState.requireValue,
    accessState.requireValue,
    definition,
  )) {
    return null;
  }

  final firstRoute = ref.read(tenantAdminFirstPermittedRouteProvider);
  if (firstRoute == null || firstRoute == definition.path) {
    return '/tenant-admin/no-access';
  }

  return firstRoute;
}

Widget _screenFor(TenantAdminRouteDefinition definition, GoRouterState state) {
  if (definition.path == '/tenant-admin/settings') {
    return const TenantLoginBrandingScreen();
  }

  if (definition.path == '/tenant-admin/dashboard') {
    return const TenantDashboardScreen();
  }

  if (definition.path == '/tenant-admin/outlets') {
    return const OutletListScreen();
  }

  if (definition.path == '/tenant-admin/outlets/add') {
    return const AddOutletScreen();
  }

  if (definition.path == '/tenant-admin/outlets/:id') {
    return OutletDetailsScreen(
      outletId: state.pathParameters['id'] ?? '',
    );
  }

  if (definition.path == '/tenant-admin/outlets/:id/edit') {
    return EditOutletScreen(
      outletId: state.pathParameters['id'] ?? '',
    );
  }

  if (definition.path == '/tenant-admin/roles') {
    return const RolesScreen();
  }

  if (definition.path == '/tenant-admin/roles/add') {
    return const CreateCustomRoleScreen();
  }

  if (definition.path == '/tenant-admin/roles/:id/edit') {
    return EditRoleScreen(
      roleId: state.pathParameters['id'] ?? '',
    );
  }

  if (definition.path == '/tenant-admin/roles-permissions/create/select-role') {
    return const RoleSetupStep1RoleScreen();
  }

  if (definition.path == '/tenant-admin/roles-permissions/create/modules') {
    return const RoleSetupStep2ModulesScreen();
  }

  if (definition.path == '/tenant-admin/roles-permissions/create/permissions') {
    return const RoleSetupStep3PermissionsScreen();
  }

  if (definition.path == '/tenant-admin/roles-permissions/create/assignments') {
    return const RoleSetupStep4AssignmentsScreen();
  }

  if (definition.path == '/tenant-admin/roles-permissions/create/review') {
    return const RoleSetupStep5ReviewScreen();
  }

  if (definition.path == '/tenant-admin/roles-permissions/:roleId') {
    return RolePermissionsScreen(
      initialRoleId: state.pathParameters['roleId'],
    );
  }

  if (definition.path == '/tenant-admin/tills') {
    return const TillMonitoringScreen();
  }

  if (definition.path == '/tenant-admin/tills/add') {
    return const AddTillScreen();
  }

  if (definition.path == '/tenant-admin/tills/:id/edit') {
    final tillId = state.pathParameters['id'];
    if (tillId == null || tillId.isEmpty) {
      return const TillMonitoringScreen();
    }

    return EditTillScreen(tillId: tillId);
  }

  if (definition.path == '/tenant-admin/tills/:id') {
    final tillId = state.pathParameters['id'];
    if (tillId == null || tillId.isEmpty) {
      return const TillMonitoringScreen();
    }

    return TillDetailsScreen(tillId: tillId);
  }

  if (definition.path == '/tenant-admin/hardware') {
    return const HardwareListScreen();
  }

  if (definition.path == '/tenant-admin/hardware/add') {
    return const AddHardwareScreen();
  }

  if (definition.path == '/tenant-admin/hardware/:id/edit') {
    final hardwareId = state.pathParameters['id'];
    if (hardwareId == null || hardwareId.isEmpty) {
      return const HardwareListScreen();
    }
    return AddHardwareScreen(hardwareId: hardwareId);
  }

  if (definition.path == '/tenant-admin/hardware/:id') {
    final hardwareId = state.pathParameters['id'];
    if (hardwareId == null || hardwareId.isEmpty) {
      return const HardwareListScreen();
    }
    return HardwareDetailScreen(hardwareId: hardwareId);
  }

  if (definition.path == '/tenant-admin/staff') {
    return const UserListScreen();
  }

  if (definition.path == '/tenant-admin/staff/add') {
    return const AddEditUserScreen();
  }

  if (definition.path == '/tenant-admin/staff/:id/edit') {
    return AddEditUserScreen(userId: state.pathParameters['id']);
  }

  if (definition.path == '/tenant-admin/staff/:id') {
    // User Details is a modal launched from the list, not a routed screen.
    return const UserListScreen();
  }

  if (definition.path == '/tenant-admin/online-store') {
    return const OnlineStoreSetupScreen(stepNumber: 1);
  }

  if (definition.path == '/tenant-admin/online-store/activation') {
    return const OnlineStoreSetupScreen(stepNumber: 2);
  }

  if (definition.path == '/tenant-admin/online-store/identity') {
    return const OnlineStoreSetupScreen(stepNumber: 3);
  }

  if (definition.path == '/tenant-admin/online-store/domain') {
    return const OnlineStoreSetupScreen(stepNumber: 4);
  }

  if (definition.path == '/tenant-admin/online-store/branding') {
    return const OnlineStoreSetupScreen(stepNumber: 5);
  }

  if (definition.path == '/tenant-admin/online-store/support') {
    return const OnlineStoreSetupScreen(stepNumber: 6);
  }

  if (definition.path == '/tenant-admin/online-store/click-collect') {
    return const OnlineStoreSetupScreen(stepNumber: 7);
  }

  if (definition.path == '/tenant-admin/online-store/products-policies') {
    return const OnlineStoreSetupScreen(stepNumber: 8);
  }

  if (definition.path == '/tenant-admin/online-store/review') {
    return const OnlineStoreSetupScreen(stepNumber: 9);
  }

  if (definition.path == ProductsSidebarRoutes.dashboard) {
    return const ProductDashboardPage();
  }

  if (definition.path == ProductsSidebarRoutes.list) {
    return const ProductListScreen();
  }

  if (definition.path == ProductsSidebarRoutes.add ||
      state.uri.path.startsWith('/tenant-admin/products/draft/') ||
      state.uri.path.startsWith('/tenant-admin/products/local-draft/')) {
    if (state.uri.path.startsWith('/tenant-admin/products/local-draft/')) {
      final localDraftId = state.pathParameters['localDraftId'] ??
          (state.uri.pathSegments.length >= 4
              ? state.uri.pathSegments[3]
              : null);
      return AddProductScreen(resumeLocalDraftId: localDraftId);
    }
    final draftId = state.pathParameters['productId'] ??
        state.pathParameters['id'] ??
        (state.uri.pathSegments.length >= 4 &&
                state.uri.pathSegments[2] == 'draft'
            ? state.uri.pathSegments[3]
            : null);
    return AddProductScreen(resumeProductId: draftId);
  }

  if (definition.path == ProductsSidebarRoutes.categories) {
    return ProductsComingSoonScreen(
      title: definition.title,
      permissionCode: definition.permissionCode,
    );
  }

  if (definition.path == ProductsSidebarRoutes.brands) {
    return const BrandListScreen();
  }

  if (definition.path == ProductsSidebarRoutes.tax) {
    return const TaxManagementPage();
  }

  if (definition.path == ProductsSidebarRoutes.variantTemplates) {
    return ProductsComingSoonScreen(
      title: definition.title,
      permissionCode: definition.permissionCode,
    );
  }

  if (definition.path == ProductsSidebarRoutes.popular) {
    return const PopularProductsCurationScreen();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.dashboard)) {
    return const InventoryDashboardPage();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.currentStock)) {
    return const CurrentStockScreen();
  }

  if (InventoryRoutes.matches(
      definition.path, InventoryRoutes.currentStockDetail)) {
    final variantId = state.pathParameters['variantId'];
    if (variantId != null) {
      return ProductStockDetailScreen(variantId: variantId);
    }
    return const TenantAdminErrorScreen();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.stockIn) ||
      InventoryRoutes.matches(definition.path, InventoryRoutes.receiving)) {
    return const ReceivingDashboardScreen();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.receivingNew)) {
    return const ReceivingWizardScreen();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.serials)) {
    return const SerialRegistryScreen();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.openingStock)) {
    return const OpeningStockWizardScreen();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.adjustment)) {
    return const AdjustmentDashboardScreen();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.adjustmentNew)) {
    return const AdjustmentWizardScreen();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.channel)) {
    return const ChannelAllocationDashboardScreen();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.channelNew)) {
    return const ChannelAllocationWizardScreen();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.channelDetail)) {
    return ChannelAllocationDetailScreen(
      id: state.pathParameters['id'] ?? '',
    );
  }

  if (definition.path == '/tenant-admin/reports') {
    return const ReportsDashboardScreen();
  }

  if (definition.path == '/tenant-admin/reports/sales') {
    return const SalesReportScreen();
  }

  if (definition.path == '/tenant-admin/reports/sales/:orderId') {
    return SalesTransactionDetailScreen(
      orderId: state.pathParameters['orderId'] ?? '',
    );
  }

  if (definition.path == '/tenant-admin/reports/stock') {
    return const StockReportScreen();
  }

  if (definition.path == '/tenant-admin/reports/outlets') {
    return const OutletReportScreen();
  }

  if (definition.path == '/tenant-admin/products/:id') {
    return ProductDetailScreen(
      productId: state.pathParameters['id'] ?? '',
    );
  }

  if (definition.path == '/tenant-admin/products/:id/edit') {
    return ProductDetailScreen(
      productId: state.pathParameters['id'] ?? '',
      isEditRoute: true,
    );
  }

  return TenantAdminPlaceholderScreen(
    title: definition.title,
    subtitle: definition.subtitle,
  );
}

class _TenantAdminGuardedScreen extends ConsumerWidget {
  const _TenantAdminGuardedScreen({
    required this.definition,
    required this.child,
  });

  final TenantAdminRouteDefinition definition;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(tenantAdminMenuProvider);
    final accessCheckerState = ref.watch(tenantAdminAccessCheckerProvider);

    return menuState.when(
      loading: () => const TenantAdminLoadingScreen(),
      error: (error, stackTrace) => TenantAdminErrorScreen(
        onRetry: () => ref.refresh(tenantAdminMenuProvider),
      ),
      data: (items) {
        return accessCheckerState.when(
          loading: () => const TenantAdminLoadingScreen(),
          error: (error, stackTrace) => TenantAdminErrorScreen(
            onRetry: () => ref.refresh(tenantAdminContextProvider),
          ),
          data: (accessChecker) {
            if (!_canAccessRoute(items, accessChecker, definition)) {
              return const TenantAdminForbiddenScreen();
            }

            return child;
          },
        );
      },
    );
  }
}

bool _canAccessRoute(
  List<TenantAdminMenuItem> items,
  TenantAdminAccessChecker accessChecker,
  TenantAdminRouteDefinition definition,
) {
  if (definition.path == '/tenant-admin/roles/add') {
    return accessChecker.canShowActionWithAnyPermission(
      TenantAdminFeatureCodes.rolePermission,
      [
        TenantAdminPermissionCodes.tenantRolesCreate,
        TenantAdminPermissionCodes.tenantRoleManage,
      ],
    );
  }

  if (definition.menuKey == 'roles-access') {
    return accessChecker.canShowActionWithAnyPermission(
      TenantAdminFeatureCodes.rolePermission,
      [
        TenantAdminPermissionCodes.rolesPermissionsView,
        TenantAdminPermissionCodes.rolesView,
        TenantAdminPermissionCodes.permissionsView,
        TenantAdminPermissionCodes.tenantRoleManage,
      ],
    );
  }

  if (definition.path.startsWith('/tenant-admin/roles-permissions')) {
    return accessChecker.can(TenantAdminPermissionCodes.rolesPermissionsView) ||
        accessChecker.canShowActionWithAnyPermission(
          TenantAdminFeatureCodes.rolePermission,
          [
            TenantAdminPermissionCodes.rolesView,
            TenantAdminPermissionCodes.permissionsView,
            TenantAdminPermissionCodes.tenantRoleManage,
          ],
        );
  }

  if (definition.path == '/tenant-admin/outlets/:id') {
    return accessChecker.canViewOutletDetail();
  }

  if (definition.path == '/tenant-admin/outlets/:id/edit') {
    return accessChecker.canEditOutlet();
  }

  if (definition.path == '/tenant-admin/outlets/add') {
    return accessChecker.canCreateOutlet();
  }

  if (definition.path == '/tenant-admin/tills/add') {
    return accessChecker.canCreateTill();
  }

  if (definition.path == '/tenant-admin/tills/:id/edit') {
    return accessChecker.canUpdateTill();
  }

  if (definition.path == '/tenant-admin/tills' ||
      definition.path == '/tenant-admin/tills/:id') {
    return accessChecker.canAccessTillModule();
  }

  if (definition.path == '/tenant-admin/hardware') {
    return accessChecker.can(TenantAdminPermissionCodes.tenantHardwareView);
  }

  if (definition.path == '/tenant-admin/hardware/add') {
    return accessChecker.can(TenantAdminPermissionCodes.tenantHardwareManage);
  }

  if (definition.path == '/tenant-admin/hardware/:id/edit') {
    return accessChecker.can(TenantAdminPermissionCodes.tenantHardwareManage);
  }

  if (definition.path == '/tenant-admin/hardware/:id') {
    return accessChecker.can(TenantAdminPermissionCodes.tenantHardwareView);
  }

  if (definition.path == '/tenant-admin/staff/add') {
    return accessChecker.canAddUser();
  }

  if (definition.path == '/tenant-admin/staff/:id/edit') {
    return accessChecker.canUpdateUser();
  }

  if (definition.path == '/tenant-admin/staff' ||
      definition.path == '/tenant-admin/staff/:id') {
    return accessChecker.canAccessUserModule();
  }

  if (definition.menuKey == 'online-store') {
    return accessChecker.canViewOnlineStore();
  }

  if (definition.path == ProductsSidebarRoutes.dashboard) {
    return accessChecker.canViewProductDashboard();
  }

  if (definition.path == ProductsSidebarRoutes.list ||
      definition.path == ProductsSidebarRoutes.add ||
      definition.path == ProductsSidebarRoutes.categories ||
      definition.path == ProductsSidebarRoutes.brands ||
      definition.path == ProductsSidebarRoutes.tax ||
      definition.path == ProductsSidebarRoutes.variantTemplates ||
      definition.path == ProductsSidebarRoutes.popular) {
    return ProductsRouteGuard.canAccessPath(accessChecker, definition.path);
  }


  if (definition.path == '/tenant-admin/products') {
    return accessChecker.canViewProductListNav();
  }

  if (definition.path == '/tenant-admin/products/add') {
    return accessChecker.canCreateProductNav();
  }

  if (definition.path == '/tenant-admin/products/:id/edit') {
    return accessChecker.canAccessProductModule() &&
        accessChecker.canUpdateProduct();
  }

  if (definition.path == '/tenant-admin/products/:id') {
    return accessChecker.canAccessProductModule();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.dashboard)) {
    return accessChecker.canAccessInventoryDashboard();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.currentStock) ||
      InventoryRoutes.matches(
          definition.path, InventoryRoutes.currentStockDetail)) {
    return accessChecker.canAccessCurrentStockPage();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.stockIn) ||
      InventoryRoutes.matches(definition.path, InventoryRoutes.receiving) ||
      InventoryRoutes.matches(definition.path, InventoryRoutes.receivingNew)) {
    return accessChecker.canAccessReceivingPage();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.serials)) {
    return accessChecker.canAccessSerialsPage();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.openingStock)) {
    return accessChecker.canAccessOpeningStockPage();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.adjustment)) {
    return accessChecker.canAccessAdjustmentPage();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.adjustmentNew)) {
    return accessChecker.canCreateStockAdjustment();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.channel) ||
      InventoryRoutes.matches(definition.path, InventoryRoutes.channelDetail)) {
    return accessChecker.canAccessChannelAllocationPage();
  }

  if (InventoryRoutes.matches(definition.path, InventoryRoutes.channelNew)) {
    return accessChecker.canManageChannelAllocation();
  }

  if (definition.path == '/tenant-admin/reports') {
    return accessChecker.canViewReportsDashboard();
  }

  if (definition.path == '/tenant-admin/reports/sales') {
    return accessChecker.canViewSalesReport();
  }

  if (definition.path == '/tenant-admin/reports/sales/:orderId') {
    return accessChecker.canViewSalesTransactionDetail();
  }

  if (definition.path == '/tenant-admin/reports/stock') {
    return accessChecker.canViewStockReport();
  }

  if (definition.path == '/tenant-admin/reports/outlets') {
    return accessChecker.canViewOutletReport();
  }

  final menuItem = _findMenuItem(items, definition.menuKey);
  if (menuItem == null || !menuItem.visible) {
    return false;
  }

  return accessChecker.canShowAction(
    definition.featureCode,
    definition.permissionCode,
  );
}

TenantAdminMenuItem? _findMenuItem(
  List<TenantAdminMenuItem> items,
  String menuKey,
) {
  for (final item in items) {
    if (item.key == menuKey) {
      return item;
    }
  }

  return null;
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';

// import '../../../../core/access/tenant_admin_access_codes.dart';
// import 'domain/entities/tenant_admin_menu_item.dart';
// import 'domain/services/tenant_admin_access_checker.dart';
// import 'role_permissions/presentation/screens/role_permissions_screen.dart';
// import 'presentation/layout/tenant_admin_layout.dart';
// import 'dashboard/presentation/screens/tenant_dashboard_screen.dart';
// import 'outlets/presentation/screens/add_outlet_screen.dart';
// import 'outlets/presentation/screens/edit_outlet_screen.dart';
// import 'outlets/presentation/screens/outlet_details_screen.dart';
// import 'outlets/presentation/screens/outlet_list_screen.dart';
// import 'tills/presentation/screens/add_till_screen.dart';
// import 'tills/presentation/screens/till_list_screen.dart';
// import '../auth/presentation/providers/session_provider.dart';
// import 'presentation/providers/tenant_admin_access_provider.dart';
// import 'presentation/providers/tenant_admin_context_provider.dart';
// import 'presentation/providers/tenant_admin_menu_provider.dart';
// import 'presentation/providers/tenant_admin_navigation_provider.dart';
// import 'presentation/routing/tenant_admin_route_definition.dart';
// import 'presentation/screens/tenant_admin_error_screen.dart';
// import 'presentation/screens/tenant_admin_forbidden_screen.dart';
// import 'presentation/screens/tenant_admin_loading_screen.dart';
// import 'presentation/screens/tenant_admin_placeholder_screen.dart';

// List<RouteBase> tenantAdminRoutes(Ref ref) {
//   return [
//     ShellRoute(
//       builder: (context, state, child) {
//         return TenantAdminLayout(
//           currentPath: state.uri.path,
//           child: child,
//         );
//       },
//       routes: [
//         GoRoute(
//           path: '/tenant-admin',
//           redirect: (context, state) {
//             final session = ref.read(authSessionProvider);
//             if (session == null || !session.isAuthenticated) {
//               return '/tenant-login';
//             }

//             final contextState = ref.read(tenantAdminContextProvider);
//             final menuState = ref.read(tenantAdminMenuProvider);

//             if (contextState.isLoading || menuState.isLoading) {
//               return '/tenant-admin/dashboard';
//             }

//             if (contextState.hasError || menuState.hasError) {
//               return '/tenant-admin/dashboard';
//             }

//             final firstRoute = ref.read(tenantAdminFirstPermittedRouteProvider);
//             if (firstRoute == null) {
//               return '/tenant-admin/no-access';
//             }

//             return firstRoute;
//           },
//         ),
//         GoRoute(
//           path: '/tenant-admin/no-access',
//           builder: (context, state) => const TenantAdminForbiddenScreen(),
//         ),
//         GoRoute(
//           path: '/tenant-admin/roles-access',
//           redirect: (context, state) => '/tenant-admin/roles-permissions',
//         ),
//         GoRoute(
//           path: '/tenant-admin/roles',
//           redirect: (context, state) => '/tenant-admin/roles-permissions',
//         ),
//         ...tenantAdminRouteDefinitions.map(
//           (definition) => _tenantAdminModuleRoute(ref, definition),
//         ),
//       ],
//     ),
//   ];
// }

// GoRoute _tenantAdminModuleRoute(
//   Ref ref,
//   TenantAdminRouteDefinition definition,
// ) {
//   return GoRoute(
//     path: definition.path,
//     redirect: (context, state) =>
//         _tenantAdminAccessRedirect(ref, definition, state.uri.path),
//     builder: (context, state) {
//       return _TenantAdminGuardedScreen(
//         definition: definition,
//         child: _screenFor(definition, state),
//       );
//     },
//   );
// }

// String? _tenantAdminAccessRedirect(
//   Ref ref,
//   TenantAdminRouteDefinition definition,
//   String currentPath,
// ) {
//   if (currentPath != definition.path) {
//     return null;
//   }

//   final menuState = ref.read(tenantAdminMenuProvider);
//   final accessState = ref.read(tenantAdminAccessCheckerProvider);

//   if (!menuState.hasValue || !accessState.hasValue) {
//     return null;
//   }

//   if (_canAccessRoute(
//     menuState.requireValue,
//     accessState.requireValue,
//     definition,
//   )) {
//     return null;
//   }

//   final firstRoute = ref.read(tenantAdminFirstPermittedRouteProvider);
//   if (firstRoute == null || firstRoute == definition.path) {
//     return '/tenant-admin/no-access';
//   }

//   return firstRoute;
// }

// Widget _screenFor(TenantAdminRouteDefinition definition, GoRouterState state) {
//   if (definition.path == '/tenant-admin/dashboard') {
//     return const TenantDashboardScreen();
//   }

//   if (definition.path == '/tenant-admin/outlets') {
//     return const OutletListScreen();
//   }

//   if (definition.path == '/tenant-admin/outlets/add') {
//     return const AddOutletScreen();
//   }

//   if (definition.path == '/tenant-admin/outlets/:id') {
//     return OutletDetailsScreen(outletId: state.pathParameters['id'] ?? '');
//   }

//   if (definition.path == '/tenant-admin/outlets/:id/edit') {
//     return EditOutletScreen(outletId: state.pathParameters['id'] ?? '');
//   }

//   if (definition.path == '/tenant-admin/roles-permissions') {
//     return RolePermissionsScreen(
//       initialRoleId: state.uri.queryParameters['roleId'],
//     );
//   }

//   if (definition.path == '/tenant-admin/roles-permissions/:roleId') {
//     return RolePermissionsScreen(
//       initialRoleId: state.pathParameters['roleId'],
//     );
//   if (definition.path == '/tenant-admin/tills') {
//     return const TillMonitoringScreen();
//   }

//   if (definition.path == '/tenant-admin/tills/add') {
//     return const AddTillScreen();
//   }

//   return TenantAdminPlaceholderScreen(
//     title: definition.title,
//     subtitle: definition.subtitle,
//   );
// }

// class _TenantAdminGuardedScreen extends ConsumerWidget {
//   const _TenantAdminGuardedScreen({
//     required this.definition,
//     required this.child,
//   });

//   final TenantAdminRouteDefinition definition;
//   final Widget child;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final menuState = ref.watch(tenantAdminMenuProvider);
//     final accessCheckerState = ref.watch(tenantAdminAccessCheckerProvider);

//     return menuState.when(
//       loading: () => const TenantAdminLoadingScreen(),
//       error: (error, stackTrace) => TenantAdminErrorScreen(
//         onRetry: () => ref.refresh(tenantAdminMenuProvider),
//       ),
//       data: (items) {
//         return accessCheckerState.when(
//           loading: () => const TenantAdminLoadingScreen(),
//           error: (error, stackTrace) => TenantAdminErrorScreen(
//             onRetry: () => ref.refresh(tenantAdminContextProvider),
//           ),
//           data: (accessChecker) {
//             if (!_canAccessRoute(items, accessChecker, definition)) {
//               return const TenantAdminForbiddenScreen();
//             }

//             return child;
//           },
//         );
//       },
//     );
//   }
// }

// bool _canAccessRoute(
//   List<TenantAdminMenuItem> items,
//   TenantAdminAccessChecker accessChecker,
//   TenantAdminRouteDefinition definition,
// ) {
//   if (definition.menuKey == 'roles-access') {
//     return accessChecker.canShowActionWithAnyPermission(
//           TenantAdminFeatureCodes.rolePermission,
//           [
//             TenantAdminPermissionCodes.rolesPermissionsView,
//             TenantAdminPermissionCodes.rolesView,
//             TenantAdminPermissionCodes.permissionsView,
//             TenantAdminPermissionCodes.tenantRoleManage,
//           ],
//         );
//   }

//   if (definition.path.startsWith('/tenant-admin/roles-permissions')) {
//     return accessChecker.can(TenantAdminPermissionCodes.rolesPermissionsView) ||
//         accessChecker.canShowActionWithAnyPermission(
//           TenantAdminFeatureCodes.rolePermission,
//           [
//             TenantAdminPermissionCodes.rolesView,
//             TenantAdminPermissionCodes.permissionsView,
//             TenantAdminPermissionCodes.tenantRoleManage,
//           ],
//         );
//   }

//   if (definition.path == '/tenant-admin/outlets/:id') {
//     return accessChecker.canViewOutletDetail();
//   }

//   if (definition.path == '/tenant-admin/outlets/:id/edit') {
//     return accessChecker.canEditOutlet();
//   }

//   if (definition.path == '/tenant-admin/outlets/add') {
//     return accessChecker.canCreateOutlet();
//   }

//   if (definition.path == '/tenant-admin/tills') {
//     return accessChecker.canAccessTillListPage();
//   }

//   if (definition.path == '/tenant-admin/tills/add') {
//     return accessChecker.canCreateTill();
//   }

//   final menuItem = _findMenuItem(items, definition.menuKey);
//   if (menuItem == null || !menuItem.visible) {
//     return false;
//   }

//   return accessChecker.canShowAction(
//     definition.featureCode,
//     definition.permissionCode,
//   );
// }

// TenantAdminMenuItem? _findMenuItem(
//   List<TenantAdminMenuItem> items,
//   String menuKey,
// ) {
//   for (final item in items) {
//     if (item.key == menuKey) {
//       return item;
//     }
//   }

//   return null;
// }
