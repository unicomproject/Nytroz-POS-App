import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_provider.dart';
import '../../../../shared/pos_session/pos_session_bootstrap_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../../workspace/domain/workspace_access.dart';
import '../../../workspace/presentation/providers/workspace_selection_provider.dart';

enum PostLoginRoute {
  workspace('/workspace'),
  noAccess('/workspace/no-access'),
  deviceActivation('/pos/device-activation'),
  openTill('/pos/open-till'),
  posHome('/pos/home'),
  tenantAdminDashboard('/tenant-admin');

  const PostLoginRoute(this.path);

  final String path;
}

final postLoginRouteProvider = Provider<PostLoginRoute>((ref) {
  final workspaceState = ref.watch(workspaceSelectionProvider);
  final access = workspaceState.access;

  if (!access.hasAny) {
    return PostLoginRoute.noAccess;
  }

  if (access.hasMultiple && workspaceState.selected == null) {
    return PostLoginRoute.workspace;
  }

  if (workspaceState.selected == AppWorkspace.tenantAdmin ||
      access.onlyWorkspace == AppWorkspace.tenantAdmin) {
    return PostLoginRoute.tenantAdminDashboard;
  }

  final bootstrap = ref.watch(posSessionBootstrapProvider);
  if (!bootstrap.isReady) {
    return PostLoginRoute.posHome;
  }

  final deviceState = ref.watch(deviceActivationProvider);
  final tillState = ref.watch(tillProvider);
  final authSession = ref.watch(authSessionProvider);
  final device = deviceState.deviceContext;
  final deviceTrusted = device?.isTrusted == true;

  final isPosCashier = authSession?.canOpenPosTill == true;

  if (isPosCashier) {
    if (!deviceTrusted) {
      developer.log(
        'Post-login navigation: Cashier requires device activation. route=${PostLoginRoute.deviceActivation.path}',
        name: 'auth.navigation',
      );
      return PostLoginRoute.deviceActivation;
    }

    if (!tillState.hasOpenSession) {
      developer.log(
        'Post-login navigation: Cashier open till required. route=${PostLoginRoute.openTill.path}',
        name: 'auth.navigation',
      );
      return PostLoginRoute.openTill;
    }

    developer.log(
      'Post-login navigation: Cashier till is open. route=${PostLoginRoute.posHome.path}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.posHome;
  }

  if (authSession?.canActivatePosDevice == true && !deviceTrusted) {
    developer.log(
      'Post-login navigation: device activation required. route=${PostLoginRoute.deviceActivation.path}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.deviceActivation;
  }

  developer.log(
    'Post-login navigation: default POS home. route=${PostLoginRoute.posHome.path}',
    name: 'auth.navigation',
  );
  return PostLoginRoute.posHome;
});

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
