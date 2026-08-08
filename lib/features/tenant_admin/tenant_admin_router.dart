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
import 'products/presentation/screens/add_product_screen.dart';
import 'products/presentation/screens/product_detail_screen.dart';
import 'products/presentation/screens/product_list_screen.dart';
import 'products/presentation/screens/popular_products_curation_screen.dart';
import 'brands/presentation/screens/brand_list_screen.dart';
import 'inventory/presentation/navigation/inventory_routes.dart';
import 'inventory/presentation/screens/current_stock_screen.dart';
import 'inventory/presentation/screens/stock_in_screen.dart';
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
          redirect: (context, state) => '/tenant-admin/roles-permissions',
        ),
        GoRoute(
          path: '/tenant-admin/roles',
          redirect: (context, state) => '/tenant-admin/roles-permissions',
        ),
        GoRoute(
          path: InventoryRoutes.stockRoot,
          redirect: (context, state) => InventoryRoutes.currentStock,
        ),
        GoRoute(
          path: '/tenant-admin/products/import',
          redirect: (context, state) => '/tenant-admin/products',
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

  if (definition.path == '/tenant-admin/roles-permissions') {
    return RolePermissionsScreen(
      initialRoleId: state.uri.queryParameters['roleId'],
    );
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

  if (definition.path == ProductsSidebarRoutes.dashboard) {
    return const ProductDashboardPage();
  }

  if (definition.path == ProductsSidebarRoutes.list) {
    return const ProductListScreen();
  }

  if (definition.path == ProductsSidebarRoutes.add) {
    return const AddProductScreen();
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

  if (definition.path == ProductsSidebarRoutes.variantTemplates) {
    return ProductsComingSoonScreen(
      title: definition.title,
      permissionCode: definition.permissionCode,
    );
  }

  if (definition.path == ProductsSidebarRoutes.popular) {
    return const PopularProductsCurationScreen();
  }

  if (definition.path == InventoryRoutes.currentStock) {
    return const CurrentStockScreen();
  }

  if (definition.path == InventoryRoutes.stockIn) {
    return const StockInScreen();
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

  if (definition.path == ProductsSidebarRoutes.dashboard) {
    return accessChecker.canViewProductDashboard();
  }

  if (definition.path == ProductsSidebarRoutes.list ||
      definition.path == ProductsSidebarRoutes.add ||
      definition.path == ProductsSidebarRoutes.categories ||
      definition.path == ProductsSidebarRoutes.brands ||
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

  if (definition.path == InventoryRoutes.currentStock) {
    return accessChecker.canAccessCurrentStockPage();
  }

  if (definition.path == InventoryRoutes.stockIn) {
    return accessChecker.canAccessStockInPage();
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
