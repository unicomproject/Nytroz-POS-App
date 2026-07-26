import '../../../../core/access/pos_permission_access.dart';
import '../../domain/entities/pos_home_action.dart';

class PosHomeDashboardState {
  const PosHomeDashboardState({
    required this.actions,
    required this.fallbackUserDisplayName,
    this.cashierRoleLabel = '',
    this.businessDisplayName = '',
    this.businessLogoUrl,
    this.outletName = '',
    this.deviceName = '',
    this.deviceStatus = '',
    this.summary,
    required this.tillLabel,
    required this.tillStatusLabel,
    this.tillDisplayLabel = '',
    required this.isTillOpen,
    required this.statusMessage,
    this.notificationCount = 0,
    this.dateDisplay = '',
    this.timeDisplay = '',
    this.serverNowUtc,
    this.serverTimeReceivedAt,
    this.outletTimezone,
    this.startSaleTitle = 'Start a Sale',
    this.startSaleDescription = '',
    this.startSaleButtonLabel = 'Start New Sale',
    this.isPosEnabled,
    this.isTrustedDevice,
    this.hasOpenTillSession,
    this.enabledFeatureKeys,
    this.grantedPermissionKeys,
  });

  final List<PosHomeAction> actions;

  // Mock/view-only fallback until a POS operator session is available.
  final String fallbackUserDisplayName;
  final String cashierRoleLabel;
  final String businessDisplayName;
  final String? businessLogoUrl;
  final String outletName;
  final String deviceName;
  final String deviceStatus;
  final PosHomeSummaryState? summary;

  // Mock/view-only copy until POS session state is implemented.
  final String tillLabel;

  // Mock/view-only status until open-till session state is implemented.
  final String tillStatusLabel;
  final String tillDisplayLabel;
  final bool isTillOpen;

  // Mock/view-only copy; opening this dashboard does not create a transaction.
  final String statusMessage;

  // Mock/view-only header and hero display values.
  final int notificationCount;
  final String dateDisplay;
  final String timeDisplay;
  final DateTime? serverNowUtc;
  final DateTime? serverTimeReceivedAt;
  final String? outletTimezone;
  final String startSaleTitle;
  final String startSaleDescription;
  final String startSaleButtonLabel;

  // Null means the corresponding POS context provider is not implemented yet.
  // Unknown context must not hide Release 1 dashboard entry points.
  final bool? isPosEnabled;
  final bool? isTrustedDevice;
  final bool? hasOpenTillSession;
  final Set<String>? enabledFeatureKeys;
  final Set<String>? grantedPermissionKeys;

  PosHomeActionAccess accessFor(PosHomeAction action) {
    if (action.isFutureFeature) {
      return const PosHomeActionAccess(
        isVisible: false,
        isEnabled: false,
      );
    }

    final hasFeature = _allowsKey(enabledFeatureKeys, action.featureKey);
    final hasPermission = action.permissionKey == null ||
        grantedPermissionKeys == null ||
        PosPermissionAccess.grantsCanonicalPermission(
          grantedPermissionKeys!,
          action.permissionKey!,
        );

    if (grantedPermissionKeys != null &&
        action.permissionKey != null &&
        !hasPermission) {
      return const PosHomeActionAccess(
        isVisible: false,
        isEnabled: false,
      );
    }

    if (enabledFeatureKeys != null &&
        action.featureKey != null &&
        !hasFeature) {
      return const PosHomeActionAccess(
        isVisible: false,
        isEnabled: false,
      );
    }

    if (!action.isEnabled || !action.routeExists) {
      return PosHomeActionAccess(
        isVisible: true,
        isEnabled: false,
        disabledMessage: action.isFutureFeature
            ? 'Coming in a future release.'
            : 'Destination is not available yet.',
      );
    }

    switch (action.key) {
      case 'start-new-sale':
        return _enabledWhen(
          conditions: [isPosEnabled, isTrustedDevice, hasOpenTillSession],
          disabledMessage:
              'POS, trusted device, and an open till are required.',
        );
      case 'parked-sales':
        return _enabledWhen(
          conditions: [isPosEnabled, hasOpenTillSession],
          disabledMessage: 'POS and an open till are required.',
        );
      case 'cash-in-out':
        return _enabledWhen(
          conditions: [hasOpenTillSession],
          disabledMessage: 'An open till is required.',
        );
      case 'returns-refunds':
      case 'manage-online-orders':
      case 'add-customer':
      case 'cash-drawer':
        return const PosHomeActionAccess(
          isVisible: true,
          isEnabled: true,
        );
      default:
        return const PosHomeActionAccess(
          isVisible: true,
          isEnabled: true,
        );
    }
  }

  PosHomeActionAccess _enabledWhen({
    required List<bool?> conditions,
    required String disabledMessage,
  }) {
    if (conditions.any((condition) => condition == false)) {
      return PosHomeActionAccess(
        isVisible: true,
        isEnabled: false,
        disabledMessage: disabledMessage,
      );
    }

    return const PosHomeActionAccess(isVisible: true, isEnabled: true);
  }
}

class PosHomeSummaryState {
  const PosHomeSummaryState({
    required this.scope,
    required this.currencyCode,
    required this.grossSalesAmount,
    required this.transactionCount,
    required this.refundAmount,
    required this.refundCount,
    required this.discountAmount,
    required this.netSalesAmount,
  });

  final String scope;
  final String currencyCode;
  final double grossSalesAmount;
  final int transactionCount;
  final double refundAmount;
  final int refundCount;
  final double discountAmount;
  final double netSalesAmount;
}

class PosHomeActionAccess {
  const PosHomeActionAccess({
    required this.isVisible,
    required this.isEnabled,
    this.disabledMessage,
  });

  final bool isVisible;
  final bool isEnabled;
  final String? disabledMessage;
}

bool _allowsKey(Set<String>? availableKeys, String? requiredKey) {
  if (requiredKey == null || availableKeys == null) {
    return true;
  }

  return availableKeys.contains(requiredKey);
}
