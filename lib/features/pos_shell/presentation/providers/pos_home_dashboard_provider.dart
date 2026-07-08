import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../../core/access/pos_permission_access.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../../shared/pos_session/pos_session_bootstrap_provider.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../application/state/pos_home_dashboard_state.dart';
import '../../data/datasources/pos_home_remote_datasource.dart';
import '../../domain/entities/pos_home_action.dart';

final posHomeRemoteDatasourceProvider =
    Provider<PosHomeRemoteDatasource>((ref) {
  return PosHomeRemoteDatasource(ref.watch(appDioProvider));
});

final posHomeDashboardProvider =
    FutureProvider<PosHomeDashboardState>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null || !session.isAuthenticated) {
    throw const PosHomeException(
      'POS home dashboard requires an authenticated session.',
    );
  }

  _ensureAuthorizationHeader(ref.read(appDioProvider), session);
  await ref.read(posSessionBootstrapProvider.notifier).bootstrap();

  final deviceContext = ref.read(deviceActivationProvider).deviceContext;
  if (deviceContext == null) {
    throw const PosHomeException('POS context is not ready.');
  }

  final tillSession = ref.read(tillProvider).session;
  final outletId = _resolveContextId(
    deviceContext.outletId,
    tillSession?.outletId,
  );
  final tillId = _resolveContextId(
    deviceContext.tillId,
    tillSession?.tillId,
  );
  final deviceId = deviceContext.deviceId.trim();

  final payload = await ref.watch(posHomeRemoteDatasourceProvider).getPosHome(
        outletId: outletId.isEmpty ? null : outletId,
        tillId: tillId.isEmpty ? null : tillId,
        deviceId: deviceId.isEmpty ? null : deviceId,
      );

  if (!payload.contextResolved) {
    throw PosHomeException(payload.userFacingErrorMessage);
  }

  final sessionPermissions = session.permissionCodes.toSet();

  return _mapPayloadToDashboardState(
    payload: payload,
    isTrustedDevice: deviceContext.isTrusted,
    hasOpenTillSession: payload.isTillOpen,
    sessionPermissions: sessionPermissions,
  );
});

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}

String _resolveContextId(String primary, String? fallback) {
  final resolved = primary.trim().isNotEmpty ? primary.trim() : fallback?.trim() ?? '';
  return resolved;
}

PosHomeDashboardState buildPosHomeShellState({
  required String userDisplayName,
  required bool isTrustedDevice,
  required bool hasOpenTillSession,
  required Set<String> permissionCodes,
}) {
  final now = DateTime.now();

  return PosHomeDashboardState(
    fallbackUserDisplayName:
        userDisplayName.trim().isEmpty ? 'Cashier' : userDisplayName.trim(),
    tillLabel: 'Till pending',
    tillStatusLabel: hasOpenTillSession ? 'Open' : 'Closed',
    tillDisplayLabel: '',
    isTillOpen: hasOpenTillSession,
    statusMessage: hasOpenTillSession
        ? 'Ready for sales'
        : 'Open a till session to start selling.',
    notificationCount: 0,
    dateDisplay: _formatDate(now),
    timeDisplay: _formatTime(now),
    startSaleTitle: 'Start a Sale',
    startSaleDescription:
        'Create a new transaction for any product, ticket, service or experience.',
    startSaleButtonLabel: 'Start New Sale',
    isPosEnabled: true,
    isTrustedDevice: isTrustedDevice,
    hasOpenTillSession: hasOpenTillSession,
    enabledFeatureKeys: const {
      PosFeatureCodes.sales,
      PosFeatureCodes.customers,
      PosFeatureCodes.returns,
      PosFeatureCodes.exchanges,
      PosFeatureCodes.till,
    },
    grantedPermissionKeys: permissionCodes,
    actions: [
      const PosHomeAction(
        key: 'start-new-sale',
        label: 'Start New Sale',
        description: 'Begin a new in-store sale.',
        iconKey: 'new-sale',
        buttonLabel: 'Start New Sale',
        isEnabled: true,
        targetRoute: '/pos/new-sale',
        featureKey: PosFeatureCodes.sales,
        permissionKey: PosPermissionCodes.viewNewSale,
      ),
      const PosHomeAction(
        key: 'returns-refunds',
        label: 'Returns & Refunds',
        description: 'Review eligible items for return or refund.',
        iconKey: 'return',
        buttonLabel: 'Start Return',
        isEnabled: true,
        targetRoute: '/pos/returns-refunds',
        featureKey: PosFeatureCodes.returns,
        permissionKey: PosPermissionCodes.viewReturns,
        metricValue: '--',
        metricLabel: 'Pending today',
      ),
      const PosHomeAction(
        key: 'add-customer',
        label: 'Add Customer',
        description: 'Create a customer profile for future visits.',
        iconKey: 'add-customer',
        buttonLabel: 'Add Customer',
        isEnabled: true,
        targetRoute: '/pos/customers',
        featureKey: PosFeatureCodes.customers,
        permissionKey: PosPermissionCodes.viewNewSaleCustomers,
        metricValue: '--',
        metricLabel: 'Customer profiles',
      ),
      const PosHomeAction(
        key: 'parked-sales',
        label: 'Parked Sales',
        description: 'View sales that were parked for later.',
        iconKey: 'parked-sales',
        buttonLabel: 'View Parked Sales',
        isEnabled: true,
        targetRoute: '/pos/parked-sales',
        featureKey: PosFeatureCodes.sales,
        permissionKey: PosPermissionCodes.createParkedSale,
        metricValue: '--',
        metricLabel: 'Waiting to resume',
      ),
      const PosHomeAction(
        key: 'cash-drawer',
        label: 'Cash Drawer',
        description: 'View the current till cash summary.',
        iconKey: 'cash-drawer',
        buttonLabel: 'View Cash Drawer',
        isEnabled: true,
        targetRoute: '/pos/cash-drawer',
        featureKey: PosFeatureCodes.till,
        permissionKey: PosPermissionCodes.viewCashDrawer,
        metricValue: '--',
        metricLabel: 'Drawer balance',
      ),
    ],
  );
}

PosHomeDashboardState _mapPayloadToDashboardState({
  required PosHomeDashboardPayload payload,
  required bool isTrustedDevice,
  required bool hasOpenTillSession,
  required Set<String> sessionPermissions,
}) {
  final receivedAt = DateTime.now().toUtc();
  final outletNow = _resolveOutletNow(
    serverNowUtc: payload.serverNowUtc,
    receivedAt: receivedAt,
    outletTimezone: payload.outletTimezone,
  );
  // Backend-provided permissions are the source of truth for what the POS can render.
  final permissions = payload.permissions.isNotEmpty
      ? payload.permissions.toSet()
      : sessionPermissions;
  final cards = payload.cards;
  final onlineOrdersCard = cards.onlineOrders;

  return PosHomeDashboardState(
    fallbackUserDisplayName: payload.userDisplayName,
    tillLabel: payload.tillName,
    tillStatusLabel: payload.tillStatusLabel,
    tillDisplayLabel: payload.tillDisplayLabel,
    isTillOpen: payload.isTillOpen,
    statusMessage: payload.statusMessage,
    notificationCount: payload.notificationCount,
    dateDisplay: _formatDate(outletNow),
    timeDisplay: _formatTime(outletNow),
    serverNowUtc: payload.serverNowUtc,
    serverTimeReceivedAt: receivedAt,
    outletTimezone: payload.outletTimezone,
    startSaleTitle: 'Start a Sale',
    startSaleDescription:
        'Create a new transaction for any product, ticket, service or experience.',
    startSaleButtonLabel: 'Start New Sale',
    isPosEnabled: true,
    isTrustedDevice: isTrustedDevice,
    hasOpenTillSession: hasOpenTillSession,
    enabledFeatureKeys: {
      PosFeatureCodes.sales,
      PosFeatureCodes.customers,
      PosFeatureCodes.returns,
      PosFeatureCodes.exchanges,
      PosFeatureCodes.till,
      if (onlineOrdersCard != null) PosFeatureCodes.onlineOrders,
    },
    grantedPermissionKeys: permissions,
    actions: [
      PosHomeAction(
        key: 'start-new-sale',
        label: 'Start New Sale',
        description: 'Begin a new in-store sale.',
        iconKey: 'new-sale',
        buttonLabel: 'Start New Sale',
        isEnabled: cards.startSale.enabled ||
            PosPermissionAccess.canAccessNewSale(permissions),
        targetRoute: '/pos/new-sale',
        featureKey: PosFeatureCodes.sales,
        permissionKey: PosPermissionCodes.viewNewSale,
      ),
      if (onlineOrdersCard != null &&
          permissions.contains(PosPermissionCodes.manageOnlineOrders))
        PosHomeAction(
          key: 'manage-online-orders',
          label: 'Manage Online Orders',
          description: 'Review incoming online orders from one place.',
          iconKey: 'online-orders',
          buttonLabel: 'View Orders',
          isEnabled: onlineOrdersCard.enabled,
          routeExists: false,
          onTapActionKey: 'manage-online-orders',
          featureKey: PosFeatureCodes.onlineOrders,
          permissionKey: PosPermissionCodes.manageOnlineOrders,
        ),
      PosHomeAction(
        key: 'returns-refunds',
        label: 'Returns & Refunds',
        description: 'Review eligible items for return or refund.',
        iconKey: 'return',
        buttonLabel: 'Start Return',
        isEnabled: cards.returnsRefunds.enabled ||
            PosPermissionAccess.canViewReturnsOrRefunds(permissions),
        targetRoute: '/pos/returns-refunds',
        featureKey: PosFeatureCodes.returns,
        permissionKey: PosPermissionCodes.viewReturns,
        metricValue: '${cards.returnsRefunds.count ?? 0}',
        metricLabel: 'Pending today',
      ),
      PosHomeAction(
        key: 'add-customer',
        label: 'Add Customer',
        description: 'Create a customer profile for future visits.',
        iconKey: 'add-customer',
        buttonLabel: 'Add Customer',
        isEnabled: cards.customers.enabled ||
            PosPermissionAccess.canViewCustomers(permissions),
        targetRoute: '/pos/customers',
        featureKey: PosFeatureCodes.customers,
        permissionKey: PosPermissionCodes.viewNewSaleCustomers,
        metricValue: '${cards.customers.count ?? 0}',
        metricLabel: 'Customer profiles',
      ),
      PosHomeAction(
        key: 'parked-sales',
        label: 'Parked Sales',
        description: 'View sales that were parked for later.',
        iconKey: 'parked-sales',
        buttonLabel: 'View Parked Sales',
        isEnabled: cards.parkedSales.enabled ||
            PosPermissionAccess.canParkOrViewParkedSales(permissions),
        targetRoute: '/pos/parked-sales',
        featureKey: PosFeatureCodes.sales,
        permissionKey: PosPermissionCodes.createParkedSale,
        metricValue: '${cards.parkedSales.count ?? 0}',
        metricLabel: 'Waiting to resume',
      ),
      PosHomeAction(
        key: 'cash-drawer',
        label: 'Cash Drawer',
        description: 'View the current till cash summary.',
        iconKey: 'cash-drawer',
        buttonLabel: 'View Cash Drawer',
        isEnabled: cards.cashDrawer.enabled ||
            PosPermissionAccess.canViewCashDrawer(permissions),
        targetRoute: '/pos/cash-drawer',
        featureKey: PosFeatureCodes.till,
        permissionKey: PosPermissionCodes.viewCashDrawer,
        metricValue: _formatCurrency(cards.cashDrawer.balance),
        metricLabel: 'Drawer balance',
      ),
    ],
  );
}

String _formatCurrency(double? value) {
  if (value == null) {
    return '--';
  }

  return 'LKR ${value.toStringAsFixed(2)}';
}

DateTime _resolveOutletNow({
  required DateTime? serverNowUtc,
  required DateTime receivedAt,
  required String? outletTimezone,
}) {
  if (serverNowUtc == null) {
    return DateTime.now();
  }

  final elapsed = DateTime.now().toUtc().difference(receivedAt);
  final anchoredUtc = serverNowUtc.add(elapsed);
  final offset = _timezoneOffset(outletTimezone);
  return anchoredUtc.add(offset);
}

Duration _timezoneOffset(String? outletTimezone) {
  switch (outletTimezone?.trim()) {
    case 'Asia/Colombo':
      return const Duration(hours: 5, minutes: 30);
    default:
      return Duration.zero;
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _formatDate(DateTime value) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${weekdays[value.weekday - 1]}, ${months[value.month - 1]} '
      '${value.day}';
}
