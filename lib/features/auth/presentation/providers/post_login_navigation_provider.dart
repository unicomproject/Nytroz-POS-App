import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_provider.dart';
import '../../../../shared/pos_session/pos_session_bootstrap_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../till/presentation/providers/till_provider.dart';

const activateDevicePermissionCode = 'tenant.till.manage';
const openTillPermissionCode = 'pos.till.open';

enum PostLoginRoute {
  deviceActivation('/pos/device-activation'),
  openTill('/pos/open-till'),
  posHome('/pos/home');

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

  if (device == null || !device.isTrusted) {
    developer.log(
      'Post-login navigation: device is not activated. route=${PostLoginRoute.deviceActivation.path}, hasPermission=${authSession?.hasPermission(activateDevicePermissionCode) == true}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.deviceActivation;
  }

  if (!tillState.hasOpenSession) {
    developer.log(
      'Post-login navigation: device activated but till is closed. route=${PostLoginRoute.openTill.path}, deviceId=${device.deviceId}, tillId=${device.tillId}, hasPermission=${authSession?.hasPermission(openTillPermissionCode) == true}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.openTill;
  }

  developer.log(
    'Post-login navigation: till is open. route=${PostLoginRoute.posHome.path}, sessionId=${tillState.session?.sessionId}',
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
