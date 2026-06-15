import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_provider.dart';
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
    var device = _ref.read(deviceActivationProvider).deviceContext;
    var tillSession = _ref.read(tillProvider).session;
    final authSession = _ref.read(authSessionProvider);

    device ??= await _ref.read(deviceContextStorageProvider).read();
    tillSession ??= await _ref.read(tillSessionStorageProvider).read();

    if (device == null || !device.isTrusted) {
      developer.log(
        'Post-login navigation resolved: device is not activated. route=${PostLoginRoute.deviceActivation.path}, hasPermission=${authSession?.hasPermission(activateDevicePermissionCode) == true}',
        name: 'auth.navigation',
      );
      return PostLoginRoute.deviceActivation;
    }

    if (tillSession == null || tillSession.status != 'open') {
      developer.log(
        'Post-login navigation resolved: device activated but till is closed. route=${PostLoginRoute.openTill.path}, deviceId=${device.deviceId}, tillId=${device.tillId}, hasPermission=${authSession?.hasPermission(openTillPermissionCode) == true}',
        name: 'auth.navigation',
      );
      return PostLoginRoute.openTill;
    }

    developer.log(
      'Post-login navigation resolved: till is open. route=${PostLoginRoute.posHome.path}, sessionId=${tillSession.sessionId}',
      name: 'auth.navigation',
    );
    return PostLoginRoute.posHome;
  }
}

final postLoginNavigationResolverProvider =
    Provider<PostLoginNavigationResolver>((ref) {
  return PostLoginNavigationResolver(ref);
});
