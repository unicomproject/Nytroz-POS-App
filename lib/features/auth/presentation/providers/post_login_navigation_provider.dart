import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_provider.dart';
import '../../../../shared/pos_session/pos_session_bootstrap_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../till/presentation/providers/till_provider.dart';

enum PostLoginRoute {
  deviceActivation('/pos/device-activation'),
  openTill('/pos/open-till'),
  posHome('/pos/home'),
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

  if (authSession?.canAccessTenantAdminDashboard == true) {
    developer.log(
      'Post-login navigation: tenant admin dashboard. route=${PostLoginRoute.tenantAdminDashboard.path}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.tenantAdminDashboard;
  }

  if (authSession?.canActivatePosDevice == true && !deviceTrusted) {
    developer.log(
      'Post-login navigation: device activation required. route=${PostLoginRoute.deviceActivation.path}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.deviceActivation;
  }

  if (authSession?.canOpenPosTill == true) {
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
