import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/session_provider.dart';
import '../../features/device_activation/presentation/providers/device_activation_provider.dart';
import '../../features/pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import '../../features/till/presentation/providers/till_provider.dart';
import 'pos_session_context.dart';

final posSessionContextProvider = Provider<PosSessionContext>((ref) {
  final authSession = ref.watch(authSessionProvider);
  final deviceContext = ref.watch(deviceActivationProvider).deviceContext;
  final tillState = ref.watch(tillProvider);
  final tillSession = tillState.session;
  final homeAsync = ref.watch(posHomeDashboardProvider);
  final tillOpen = resolveAuthoritativeTillOpen(
    homeAsync: homeAsync,
    localTillOpen: tillState.hasOpenSession,
  );

  final deviceName = deviceContext?.deviceName.trim();
  final deviceCode = deviceContext?.deviceCode.trim();
  final outletName = deviceContext?.outletName.trim();
  final tillName = deviceContext?.tillName.trim();

  return PosSessionContext(
    brandName: 'OneVerz',
    brandSubtitle: 'POS',
    outletName: _valueOrPending(outletName, 'Outlet pending'),
    outletLocation: '',
    tillName: _valueOrPending(tillName, 'Till pending'),
    tillStatus: tillOpen ? 'Open' : 'Not opened',
    userName: _valueOrPending(authSession?.userDisplayName, 'Signed-in user'),
    userRole: '',
    deviceName: _valueOrPending(deviceName, 'Web POS'),
    deviceCode: _valueOrPending(deviceCode, 'Unpaired device'),
    systemStatus: deviceContext?.isTrusted == true
        ? 'Device trusted'
        : 'Device activation required',
    lastSyncLabel: tillSession == null
        ? 'No till session'
        : 'Till opened ${_formatTime(tillSession.openedAt)}',
  );
});

String _valueOrPending(String? value, String fallback) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return fallback;
  }

  return trimmed;
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
