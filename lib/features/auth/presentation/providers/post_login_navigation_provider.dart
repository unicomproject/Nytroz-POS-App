import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_provider.dart';
import '../../../../core/access/pos_permission_access.dart';
import '../../../../core/access/pos_access_codes.dart';
import '../../../../core/access/tenant_admin_permission_aliases.dart';
import '../../../../shared/pos_session/pos_session_bootstrap_provider.dart';
import '../../domain/entities/auth_session.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../../tenant_admin/presentation/routing/tenant_admin_route_definition.dart';

enum PostLoginRoute {
  deviceActivation('/pos/device-activation'),
  openTill('/pos/open-till'),
  posHome('/pos/home'),
  posNewSale('/pos/new-sale'),
  posNoAccess('/pos/no-access'),
  tenantAdminRoot('/tenant-admin'),
  tenantAdminNoAccess('/tenant-admin/no-access'),
  tenantAdminDashboard('/tenant-admin/dashboard');

  const PostLoginRoute(this.path);

  final String path;
}

final postLoginRouteProvider = Provider<PostLoginRoute>((ref) {
  final bootstrap = ref.watch(posSessionBootstrapProvider);
  if (!bootstrap.isReady) {
    return PostLoginRoute.posHome;
  }

  final deviceState = ref.watch(deviceActivationProvider);
  final tillState = ref.watch(tillProvider);
  final authSession = ref.watch(authSessionProvider);
  final device = deviceState.deviceContext;
  final deviceTrusted = device?.isTrusted == true;

  final canAccessTenantAdminDashboard =
      authSession?.canAccessTenantAdminDashboard == true;
  final canAccessTenantAdminPortal = _canAccessTenantAdminPortal(authSession);
  final firstAccessiblePosRoute = _firstAccessiblePosRoute(authSession);
  final canAccessPosHome = firstAccessiblePosRoute == PostLoginRoute.posHome;
  final isPosUser = authSession?.isPosUser == true;
  final isTenantAdminUser = authSession?.isTenantAdminUser == true;

  if (isTenantAdminUser && canAccessTenantAdminDashboard) {
    developer.log(
      'Post-login navigation: tenant admin dashboard. route=${PostLoginRoute.tenantAdminDashboard.path}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.tenantAdminDashboard;
  }

  if (isPosUser && authSession?.canOpenPosTill == true && !deviceTrusted) {
    developer.log(
      'Post-login navigation: device activation required. route=${PostLoginRoute.deviceActivation.path}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.deviceActivation;
  }

  if (isPosUser &&
      authSession?.canActivatePosDevice == true &&
      !deviceTrusted) {
    developer.log(
      'Post-login navigation: device activation required. route=${PostLoginRoute.deviceActivation.path}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.deviceActivation;
  }

  if (isPosUser && authSession?.canOpenPosTill == true) {
    if (!tillState.hasOpenSession) {
      developer.log(
        'Post-login navigation: open till required. '
        'deviceTrusted=$deviceTrusted hasOpenSession=${tillState.hasOpenSession} '
        'route=${PostLoginRoute.openTill.path}',
        name: 'auth.navigation',
      );
      return PostLoginRoute.openTill;
    }

    developer.log(
      'Post-login navigation: till is open. route=${PostLoginRoute.posHome.path}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.posHome;
  }

  if (isPosUser && canAccessPosHome) {
    developer.log(
      'Post-login navigation: POS home authorized. route=${PostLoginRoute.posHome.path}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.posHome;
  }

  if (isPosUser && firstAccessiblePosRoute != null) {
    developer.log(
      'Post-login navigation: first POS route authorized. route=${firstAccessiblePosRoute.path}',
      name: 'auth.navigation',
    );
    return firstAccessiblePosRoute;
  }

  if (isPosUser) {
    developer.log(
      'Post-login navigation: POS identity has no usable route. route=${PostLoginRoute.posNoAccess.path}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.posNoAccess;
  }

  if (canAccessTenantAdminDashboard) {
    developer.log(
      'Post-login navigation: tenant admin dashboard. route=${PostLoginRoute.tenantAdminDashboard.path}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.tenantAdminDashboard;
  }

  if (canAccessTenantAdminPortal) {
    developer.log(
      'Post-login navigation: tenant admin shell. route=${PostLoginRoute.tenantAdminRoot.path}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.tenantAdminRoot;
  }

  if (_hasAnyPosPermission(authSession)) {
    developer.log(
      'Post-login navigation: POS identity has no usable route. route=${PostLoginRoute.posNoAccess.path}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.posNoAccess;
  }

  developer.log(
    'Post-login navigation: no usable route. route=${PostLoginRoute.tenantAdminNoAccess.path}',
    name: 'auth.navigation',
  );
  return PostLoginRoute.tenantAdminNoAccess;
});

bool _canAccessTenantAdminPortal(AuthSession? session) {
  if (session == null) {
    return false;
  }

  if (session.canAccessTenantAdminDashboard) {
    return true;
  }

  final grantedCodes = session.permissionCodes.toSet();
  for (final definition in tenantAdminRouteDefinitions) {
    final acceptedCodes =
        TenantAdminPermissionAliases.expand(definition.permissionCode);
    if (acceptedCodes.any(grantedCodes.contains)) {
      return true;
    }
  }

  return false;
}

PostLoginRoute? _firstAccessiblePosRoute(AuthSession? session) {
  if (session == null) {
    return null;
  }

  final granted = session.permissionCodes.toSet();
  if (PosPermissionAccess.canViewHome(granted)) {
    return PostLoginRoute.posHome;
  }

  if (PosPermissionAccess.canAccessNewSale(granted)) {
    return PostLoginRoute.posNewSale;
  }

  return null;
}

bool _hasAnyPosPermission(AuthSession? session) {
  if (session == null) {
    return false;
  }

  return session.permissionCodes.any(
    (code) =>
        code.startsWith('pos.') ||
        code.startsWith('sales.') ||
        code.startsWith('payments.') ||
        code.startsWith('receipts.') ||
        code.startsWith('returns.') ||
        code.startsWith('refunds.') ||
        code.startsWith('exchanges.') ||
        code.startsWith('cash_drawer.') ||
        code == PosPermissionCodes.viewTillSession ||
        code == PosPermissionCodes.openTill ||
        code == PosPermissionCodes.closeTill,
  );
}

class PostLoginNavigationResolver {
  const PostLoginNavigationResolver(this._ref);

  final Ref _ref;

  Future<PostLoginRoute> resolve() async {
    await _ref.read(posSessionBootstrapProvider.notifier).bootstrap();
    return _ref.read(postLoginRouteProvider);
  }
}

final postLoginNavigationResolverProvider =
    Provider<PostLoginNavigationResolver>((ref) {
  return PostLoginNavigationResolver(ref);
});
