import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../application/state/pos_home_dashboard_state.dart';
import '../../data/datasources/pos_home_remote_datasource.dart';
import '../../domain/entities/pos_home_action.dart';

final posHomeRemoteDatasourceProvider = Provider<PosHomeRemoteDatasource>((ref) {
  return PosHomeRemoteDatasource(ref.watch(appDioProvider));
});

final posHomeDashboardProvider =
    FutureProvider<PosHomeDashboardState>((ref) async {
  final deviceContext = ref.watch(deviceActivationProvider).deviceContext;
  final tillSession = ref.watch(tillProvider).session;

  if (deviceContext == null || tillSession == null) {
    throw const PosHomeException('POS context is not ready.');
  }

  final payload = await ref.watch(posHomeRemoteDatasourceProvider).getPosHome(
        outletId: deviceContext.outletId,
        tillId: deviceContext.tillId,
      );

  return _mapPayloadToDashboardState(
    payload: payload,
    isTrustedDevice: deviceContext.isTrusted,
    hasOpenTillSession: tillSession.status == 'open',
  );
});

PosHomeDashboardState _mapPayloadToDashboardState({
  required PosHomeDashboardPayload payload,
  required bool isTrustedDevice,
  required bool hasOpenTillSession,
}) {
  final now = DateTime.now();
  final permissions = payload.permissions.toSet();
  final cards = payload.cards;

  return PosHomeDashboardState(
    fallbackUserDisplayName: payload.userDisplayName,
    tillLabel: payload.tillName,
    tillStatusLabel: payload.isTillOpen ? 'Open' : 'Closed',
    isTillOpen: payload.isTillOpen,
    statusMessage: payload.statusMessage,
    notificationCount: payload.notificationCount,
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
    grantedPermissionKeys: permissions,
    actions: [
      PosHomeAction(
        key: 'start-new-sale',
        label: 'Start New Sale',
        description: 'Begin a new in-store sale.',
        iconKey: 'new-sale',
        buttonLabel: 'Start New Sale',
        isEnabled: cards.startSale.enabled,
        routeExists: false,
        onTapActionKey: 'start-new-sale',
        featureKey: PosFeatureCodes.sales,
        permissionKey: PosPermissionCodes.startSale,
      ),
      PosHomeAction(
        key: 'manage-online-orders',
        label: 'Manage Online Orders',
        description: 'Review incoming online orders from one place.',
        iconKey: 'online-orders',
        buttonLabel: 'View Orders',
        isEnabled: cards.onlineOrders.enabled,
        routeExists: false,
        onTapActionKey: 'manage-online-orders',
        permissionKey: PosPermissionCodes.manageOnlineOrders,
      ),
      PosHomeAction(
        key: 'returns-refunds',
        label: 'Returns & Refunds',
        description: 'Review eligible items for return or refund.',
        iconKey: 'return',
        buttonLabel: 'Start Return',
        isEnabled: cards.returnsRefunds.enabled,
        routeExists: false,
        onTapActionKey: 'returns-refunds',
        featureKey: PosFeatureCodes.returns,
        permissionKey: PosPermissionCodes.processRefund,
        metricValue: '${cards.returnsRefunds.count ?? 0}',
        metricLabel: 'Pending today',
      ),
      PosHomeAction(
        key: 'add-customer',
        label: 'Add Customer',
        description: 'Create a customer profile for future visits.',
        iconKey: 'add-customer',
        buttonLabel: 'Add Customer',
        isEnabled: cards.customers.enabled,
        routeExists: false,
        onTapActionKey: 'add-customer',
        featureKey: PosFeatureCodes.customers,
        permissionKey: PosPermissionCodes.viewCustomers,
        metricValue: '${cards.customers.count ?? 0}',
        metricLabel: 'Customer profiles',
      ),
      PosHomeAction(
        key: 'parked-sales',
        label: 'Parked Sales',
        description: 'View sales that were parked for later.',
        iconKey: 'parked-sales',
        buttonLabel: 'View Parked Sales',
        isEnabled: cards.parkedSales.enabled,
        routeExists: false,
        onTapActionKey: 'parked-sales',
        featureKey: PosFeatureCodes.sales,
        permissionKey: PosPermissionCodes.recallSale,
        metricValue: '${cards.parkedSales.count ?? 0}',
        metricLabel: 'Waiting to resume',
      ),
      PosHomeAction(
        key: 'cash-drawer',
        label: 'Cash Drawer',
        description: 'View the current till cash summary.',
        iconKey: 'cash-drawer',
        buttonLabel: 'View Cash Drawer',
        isEnabled: cards.cashDrawer.enabled,
        routeExists: false,
        onTapActionKey: 'cash-drawer',
        featureKey: PosFeatureCodes.till,
        permissionKey: PosPermissionCodes.viewTill,
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
