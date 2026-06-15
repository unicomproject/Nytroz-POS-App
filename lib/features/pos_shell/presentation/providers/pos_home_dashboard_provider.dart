import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/state/pos_home_dashboard_state.dart';
import '../../domain/entities/pos_home_action.dart';

final posHomeDashboardProvider = Provider<PosHomeDashboardState>((ref) {
  return const PosHomeDashboardState(
    fallbackUserDisplayName: 'Cashier',
    tillLabel: 'Till 01',
    tillStatusLabel: 'Open',
    isTillOpen: true,
    statusMessage: 'Till 01 is open and ready to take sales.',
    notificationCount: 3,
    dateDisplay: 'Fri, Jun 12',
    timeDisplay: '10:24 AM',
    startSaleTitle: 'Start a Sale',
    startSaleDescription: 'Scan products and create a new in-store sale.',
    startSaleButtonLabel: 'Start New Sale',
    // TODO: Wire confirmed POS entitlement, device trust, till session, and
    // permission providers. Null preserves visibility without granting access.
    isPosEnabled: null,
    isTrustedDevice: null,
    hasOpenTillSession: null,
    enabledFeatureKeys: null,
    grantedPermissionKeys: null,
    actions: [
      // TODO: Map to the confirmed start-sale route when it exists.
      PosHomeAction(
        key: 'start-new-sale',
        label: 'Start New Sale',
        description: 'Begin a new in-store sale.',
        iconKey: 'new-sale',
        buttonLabel: 'Start New Sale',
        isFutureFeature: false,
        isEnabled: false,
        routeExists: false,
        onTapActionKey: 'start-new-sale',
      ),
      // TODO: Online orders are future-feature UI; no destination route exists.
      PosHomeAction(
        key: 'manage-online-orders',
        label: 'Manage Online Orders',
        description: 'Review incoming online orders from one place.',
        iconKey: 'online-orders',
        buttonLabel: 'View Orders',
        isFutureFeature: true,
        isEnabled: false,
        routeExists: false,
        onTapActionKey: 'manage-online-orders',
        metricValue: '8',
        metricLabel: 'New orders',
      ),
      // TODO: Map to the confirmed returns/refunds route when it exists.
      PosHomeAction(
        key: 'returns-refunds',
        label: 'Returns & Refunds',
        description: 'Review eligible items for return or refund.',
        iconKey: 'return',
        buttonLabel: 'Start Return',
        isFutureFeature: false,
        isEnabled: false,
        routeExists: false,
        onTapActionKey: 'returns-refunds',
        metricValue: '2',
        metricLabel: 'Pending today',
      ),
      // TODO: Customer creation is future-feature UI; no route exists.
      PosHomeAction(
        key: 'add-customer',
        label: 'Add Customer',
        description: 'Create a customer profile for future visits.',
        iconKey: 'add-customer',
        buttonLabel: 'Add Customer',
        isFutureFeature: true,
        isEnabled: false,
        routeExists: false,
        onTapActionKey: 'add-customer',
        metricValue: '124',
        metricLabel: 'Customer profiles',
      ),
      // TODO: Map to the confirmed parked-sales route when it exists.
      PosHomeAction(
        key: 'parked-sales',
        label: 'Parked Sales',
        description: 'View sales that were parked for later.',
        iconKey: 'parked-sales',
        buttonLabel: 'View Parked Sales',
        isFutureFeature: false,
        isEnabled: false,
        routeExists: false,
        onTapActionKey: 'parked-sales',
        metricValue: '3',
        metricLabel: 'Waiting to resume',
      ),
      // TODO: Map to the confirmed cash-drawer route when it exists.
      PosHomeAction(
        key: 'cash-drawer',
        label: 'Cash Drawer',
        description: 'View the current till cash summary.',
        iconKey: 'cash-drawer',
        buttonLabel: 'View Cash Drawer',
        isFutureFeature: false,
        isEnabled: false,
        routeExists: false,
        onTapActionKey: 'cash-drawer',
        metricValue: r'$1,240.00',
        metricLabel: 'Mock drawer balance',
      ),
    ],
  );
});

// TODO: Add featureKey and permissionKey values when POS permission codes are
// confirmed by the authorization contract. Tenant-admin codes are not reused.
// TODO: Replace mock operator/till context with confirmed POS session providers.
// TODO: Map dashboard buttons when confirmed POS destination routes are added.
