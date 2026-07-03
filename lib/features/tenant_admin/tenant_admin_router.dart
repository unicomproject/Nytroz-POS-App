
//new
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/tenant_admin_access_codes.dart';
import 'domain/entities/tenant_admin_menu_item.dart';
import 'domain/services/tenant_admin_access_checker.dart';
import 'role_permissions/presentation/screens/role_permissions_screen.dart';
import 'presentation/layout/tenant_admin_layout.dart';
import 'dashboard/presentation/screens/tenant_dashboard_screen.dart';
import 'outlets/presentation/screens/add_outlet_screen.dart';
import 'outlets/presentation/screens/edit_outlet_screen.dart';
import 'outlets/presentation/screens/outlet_details_screen.dart';
import 'outlets/presentation/screens/outlet_list_screen.dart';
import 'tills/presentation/screens/add_till_screen.dart';
import 'tills/presentation/screens/till_list_screen.dart';
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
    return const TillListScreen();
  }

  if (definition.path == '/tenant-admin/tills/add') {
    return const AddTillScreen();
  }

  if (definition.path == '/tenant-admin/tills') {
    return const TillListScreen();
  }

  if (definition.path == '/tenant-admin/tills/add') {
    return const AddTillScreen();
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
//     return const TillListScreen();
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