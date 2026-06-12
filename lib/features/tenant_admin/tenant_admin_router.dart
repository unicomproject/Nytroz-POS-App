import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/entities/tenant_admin_menu_item.dart';
import 'presentation/layout/tenant_admin_layout.dart';
import 'dashboard/presentation/screens/tenant_dashboard_screen.dart';
import 'outlets/presentation/screens/add_outlet_screen.dart';
import 'outlets/presentation/screens/edit_outlet_screen.dart';
import 'outlets/presentation/screens/outlet_details_screen.dart';
import 'outlets/presentation/screens/outlet_list_screen.dart';
import 'presentation/providers/tenant_admin_access_provider.dart';
import 'presentation/providers/tenant_admin_context_provider.dart';
import 'presentation/providers/tenant_admin_menu_provider.dart';
import 'presentation/routing/tenant_admin_route_definition.dart';
import 'presentation/screens/tenant_admin_error_screen.dart';
import 'presentation/screens/tenant_admin_forbidden_screen.dart';
import 'presentation/screens/tenant_admin_loading_screen.dart';
import 'presentation/screens/tenant_admin_placeholder_screen.dart';

List<RouteBase> tenantAdminRoutes() {
  return [
    ShellRoute(
      builder: (context, state, child) {
        return TenantAdminLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/tenant-admin',
          redirect: (context, state) => '/tenant-admin/dashboard',
        ),
        GoRoute(
          path: '/tenant-admin/roles-access',
          redirect: (context, state) => '/tenant-admin/roles',
        ),
        ...tenantAdminRouteDefinitions.map(_tenantAdminModuleRoute),
      ],
    ),
  ];
}

GoRoute _tenantAdminModuleRoute(TenantAdminRouteDefinition definition) {
  return GoRoute(
    path: definition.path,
    builder: (context, state) {
      return _TenantAdminGuardedScreen(
        definition: definition,
        child: _screenFor(definition, state),
      );
    },
  );
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
    return OutletDetailsScreen(outletId: state.pathParameters['id'] ?? '');
  }

  if (definition.path == '/tenant-admin/outlets/:id/edit') {
    return EditOutletScreen(outletId: state.pathParameters['id'] ?? '');
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
        final menuItem = _findMenuItem(items, definition.menuKey);

        if (menuItem == null) {
          return const TenantAdminForbiddenScreen();
        }

        return accessCheckerState.when(
          loading: () => const TenantAdminLoadingScreen(),
          error: (error, stackTrace) => TenantAdminErrorScreen(
            onRetry: () => ref.refresh(tenantAdminContextProvider),
          ),
          data: (accessChecker) {
            final canAccessParentMenu = menuItem.visible;
            final canAccessRoute = accessChecker.canShowAction(
              definition.featureCode,
              definition.permissionCode,
            );

            if (!canAccessParentMenu || !canAccessRoute) {
              return const TenantAdminForbiddenScreen();
            }

            return child;
          },
        );
      },
    );
  }
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
