import '../../domain/entities/pos_home_action.dart';

class PosHomeDashboardState {
  const PosHomeDashboardState({
    required this.actions,
    required this.fallbackUserDisplayName,
    required this.tillLabel,
    required this.tillStatusLabel,
    required this.isTillOpen,
    required this.statusMessage,
    this.notificationCount = 0,
    this.dateDisplay = '',
    this.timeDisplay = '',
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

  // Mock/view-only copy until POS session state is implemented.
  final String tillLabel;

  // Mock/view-only status until open-till session state is implemented.
  final String tillStatusLabel;
  final bool isTillOpen;

  // Mock/view-only copy; opening this dashboard does not create a transaction.
  final String statusMessage;

  // Mock/view-only header and hero display values.
  final int notificationCount;
  final String dateDisplay;
  final String timeDisplay;
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
    final hasPermission = _allowsKey(
      grantedPermissionKeys,
      action.permissionKey,
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
