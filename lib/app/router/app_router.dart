import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/pos_shell/pos_shell_router.dart';
import '../../features/device_activation/device_activation_router.dart';
import '../../features/till/till_router.dart';
import '../../features/tenant_admin/presentation/providers/tenant_admin_menu_provider.dart';
import '../../features/tenant_admin/tenant_admin_router.dart';
import '../../features/auth/presentation/providers/post_login_navigation_provider.dart';
import '../../features/auth/presentation/providers/session_provider.dart';
import '../../features/device_activation/presentation/providers/device_activation_provider.dart';
import '../../features/till/presentation/providers/till_provider.dart';
import '../../features/auth/auth_router.dart';
import '../../shared/pos_session/pos_session_boot_screen.dart';
import '../../shared/pos_session/pos_session_bootstrap_provider.dart';
import '../../features/workspace/domain/workspace_access.dart';
import '../../features/workspace/presentation/providers/workspace_selection_provider.dart';
import '../../features/workspace/workspace_router.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  bool _isScheduled = false;

  void refresh() {
    if (!_isScheduled) {
      _isScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _isScheduled = false;
        notifyListeners();
      });
    }
  }
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);
  ref.listen(authSessionProvider, (_, __) => notifier.refresh());
  ref.listen(authSessionHydratedProvider, (_, __) => notifier.refresh());
  ref.listen(posSessionBootstrapProvider, (_, __) => notifier.refresh());
  ref.listen(postLoginRouteProvider, (_, __) => notifier.refresh());
  ref.listen(workspaceSelectionProvider, (_, __) => notifier.refresh());
  ref.listen(deviceActivationProvider, (previous, next) {
    if (ref.read(posSessionBootstrapProvider).isReady) {
      notifier.refresh();
    }
  });
  ref.listen(tenantAdminMenuProvider, (_, __) => notifier.refresh());
  ref.listen(tillProvider, (previous, next) {
    if (ref.read(posSessionBootstrapProvider).isReady) {
      notifier.refresh();
    }
  });
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  final router = GoRouter(
    refreshListenable: refresh,
    initialLocation: posSessionBootRoute,
    overridePlatformDefaultLocation: !kIsWeb,
    routes: [
      ...authRoutes(),
      ...workspaceRoutes(ref),
      GoRoute(
        path: posSessionBootRoute,
        builder: (context, state) => const PosSessionBootScreen(),
      ),
      ...deviceActivationRoutes(ref),
      ...tillRoutes(ref),
      ...posShellRoutes(ref),
      ...tenantAdminRoutes(ref),
    ],
    redirect: (context, state) {
      final session = ref.read(authSessionProvider);
      final isAuthenticated = session?.isAuthenticated ?? false;
      final authSessionHydrated = ref.read(authSessionHydratedProvider);
      final bootstrap = ref.read(posSessionBootstrapProvider);
      final authenticatedInitialRoute = ref.read(postLoginRouteProvider).path;
      final workspaceState = ref.read(workspaceSelectionProvider);
      final path = state.uri.path;
      final destination = resolveAppRedirect(
        path: path,
        authSessionHydrated: authSessionHydrated,
        isAuthenticated: isAuthenticated,
        bootstrapReady: bootstrap.isReady,
        authenticatedInitialRoute: authenticatedInitialRoute,
        canAccessTenantAdmin: workspaceState.access.canAccessTenantAdmin,
        canAccessPos: workspaceState.access.canAccessPos,
        selectedWorkspace: workspaceState.selected,
      );

      if (kDebugMode && destination != null && destination != path) {
        debugPrint(
          '[startup] redirect path=$path hydrated=$authSessionHydrated '
          'authenticated=$isAuthenticated bootstrapReady=${bootstrap.isReady} '
          'destination=$destination',
        );
      }
      return destination;
    },
  );

  ref.onDispose(router.dispose);
  return router;
});

@visibleForTesting
String? resolveAppRedirect({
  required String path,
  required bool authSessionHydrated,
  required bool isAuthenticated,
  required bool bootstrapReady,
  required String authenticatedInitialRoute,
  bool canAccessTenantAdmin = false,
  bool canAccessPos = true,
  AppWorkspace? selectedWorkspace,
}) {
  final isPublicExternalRoute = path.startsWith('/tenant-admin/payment') ||
      path.startsWith('/tenant-admin/setup');
  final isAuthRoute = path == '/tenant-login' || isPublicExternalRoute;
  final isTenantAdminRoute = path.startsWith('/tenant-admin');
  final isWorkspaceRoute = path == workspaceChooserRoute ||
      path == workspaceNoAccessRoute ||
      path == workspaceAccountSettingsRoute;
  final isProtectedPosRoute = path == posSessionBootRoute ||
      path == '/device-activation' ||
      path == '/open-till' ||
      path == '/till-open' ||
      path.startsWith('/pos/');

  if (!authSessionHydrated && !isPublicExternalRoute) {
    return path == posSessionBootRoute ? null : posSessionBootRoute;
  }

  if (isTenantAdminRoute && !isAuthRoute && !isAuthenticated) {
    return '/tenant-login';
  }

  if (isProtectedPosRoute && !isAuthenticated) {
    return '/tenant-login';
  }

  if (isWorkspaceRoute && !isAuthenticated) {
    return '/tenant-login';
  }

  if (isAuthenticated && !bootstrapReady) {
    return path == posSessionBootRoute ? null : posSessionBootRoute;
  }

  if (path == posSessionBootRoute && bootstrapReady) {
    return authenticatedInitialRoute;
  }

  if (path == '/tenant-login' && isAuthenticated) {
    return bootstrapReady ? authenticatedInitialRoute : posSessionBootRoute;
  }

  if (bootstrapReady && isAuthenticated) {
    if (!canAccessTenantAdmin && !canAccessPos) {
      return path == workspaceNoAccessRoute ? null : workspaceNoAccessRoute;
    }

    if (path == workspaceNoAccessRoute) {
      return authenticatedInitialRoute;
    }

    if (canAccessTenantAdmin && canAccessPos && selectedWorkspace == null) {
      return path == workspaceChooserRoute ||
              path == workspaceAccountSettingsRoute
          ? null
          : workspaceChooserRoute;
    }

    if (path == workspaceChooserRoute &&
        !(canAccessTenantAdmin && canAccessPos && selectedWorkspace == null)) {
      return authenticatedInitialRoute;
    }

    if (isTenantAdminRoute && !isPublicExternalRoute) {
      if (!canAccessTenantAdmin || selectedWorkspace == AppWorkspace.pos) {
        return authenticatedInitialRoute;
      }
    }

    if (isProtectedPosRoute) {
      if (!canAccessPos || selectedWorkspace == AppWorkspace.tenantAdmin) {
        return authenticatedInitialRoute;
      }
    }

    if ((path == '/device-activation' || path == '/pos/device-activation') &&
        authenticatedInitialRoute != PostLoginRoute.deviceActivation.path) {
      return authenticatedInitialRoute;
    }

    if ((path == '/open-till' ||
            path == '/till-open' ||
            path == '/pos/open-till') &&
        authenticatedInitialRoute == PostLoginRoute.posHome.path) {
      return authenticatedInitialRoute;
    }

    if (path.startsWith('/pos/') &&
        authenticatedInitialRoute != PostLoginRoute.posHome.path &&
        path != authenticatedInitialRoute) {
      return authenticatedInitialRoute;
    }

    if (path.startsWith('/tenant-admin') &&
        authenticatedInitialRoute != PostLoginRoute.tenantAdminDashboard.path &&
        !isPublicExternalRoute &&
        authenticatedInitialRoute.startsWith('/pos/')) {
      return authenticatedInitialRoute;
    }
  }

  return null;
}
