import '../../../../../core/access/effective_permission_set.dart';
import '../../../../../core/access/pos_access_codes.dart';
import '../../../../../core/access/pos_permission_access.dart';

/// Shared top-bar visibility helpers — same semantics on phone/tablet/desktop.
class PosShellTopBarVisibility {
  const PosShellTopBarVisibility._();

  static bool canShowContainer(EffectivePermissionSet permissions) {
    return permissions.hasPermission(PosPermissionCodes.shellTopbarContainer);
  }

  /// Container alone does not authorize children. Collapse empty strip when
  /// no child capability is effective.
  static bool canShowAnyChild(EffectivePermissionSet permissions) {
    return permissions.hasAnyPermission(
      PosPermissionAccess.shellTopBarChildCodes,
    );
  }

  static bool shouldRenderTopBar(EffectivePermissionSet permissions) {
    return canShowContainer(permissions) && canShowAnyChild(permissions);
  }

  static bool canShowBrand(EffectivePermissionSet permissions) {
    return permissions.hasPermission(PosPermissionCodes.shellTopbarBrand);
  }

  static bool canShowSessionStatus(EffectivePermissionSet permissions) {
    return permissions.hasPermission(
      PosPermissionCodes.shellTopbarSessionStatus,
    );
  }

  static bool canShowOutlet(EffectivePermissionSet permissions) {
    return permissions.hasPermission(PosPermissionCodes.shellTopbarOutlet);
  }

  static bool canShowTill(EffectivePermissionSet permissions) {
    return permissions.hasPermission(PosPermissionCodes.shellTopbarTill);
  }

  static bool canShowConnectivity(EffectivePermissionSet permissions) {
    return permissions.hasPermission(
      PosPermissionCodes.shellTopbarConnectivity,
    );
  }

  static bool canShowClock(EffectivePermissionSet permissions) {
    return permissions.hasPermission(PosPermissionCodes.shellTopbarClock);
  }

  static bool canShowNotificationBell(EffectivePermissionSet permissions) {
    return permissions.hasPermission(
      PosPermissionCodes.shellTopbarNotificationBell,
    );
  }

  static bool canShowNotificationPanel(EffectivePermissionSet permissions) {
    return permissions.hasPermission(
      PosPermissionCodes.notificationsPanelView,
    );
  }

  static bool canShowUnreadCount(EffectivePermissionSet permissions) {
    return permissions.hasPermission(
      PosPermissionCodes.notificationsPanelUnreadCount,
    );
  }
}
