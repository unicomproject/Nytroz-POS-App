import '../entities/tenant_admin_context.dart';
import '../entities/tenant_admin_menu_item.dart';

class TenantAdminAccessChecker {
  const TenantAdminAccessChecker(this._context);

  final TenantAdminContext _context;

  bool canAccessFeature(String featureCode) {
    if (featureCode.trim().isEmpty) {
      return false;
    }

    final hasEntitlement = _context.featureEntitlements.any(
      (feature) => feature.featureCode == featureCode && feature.enabled,
    );

    if (!hasEntitlement) {
      return false;
    }

    return _context.runtimeFlags
        .where((flag) => flag.featureCode == featureCode)
        .every((flag) => flag.enabled);
  }

  bool canUsePermission(String permissionCode) {
    if (permissionCode.trim().isEmpty) {
      return false;
    }

    return _context.permissions.any(
      (permission) => permission.permissionCode == permissionCode,
    );
  }

  bool canAccessOutlet(String outletId) {
    if (outletId.trim().isEmpty) {
      return false;
    }

    return _context.outletScope.any((outlet) => outlet.outletId == outletId);
  }

  bool canShowAction(
    String featureCode,
    String permissionCode, {
    String? outletId,
  }) {
    final hasFeatureAndPermission =
        canAccessFeature(featureCode) && canUsePermission(permissionCode);

    if (!hasFeatureAndPermission) {
      return false;
    }

    if (outletId == null) {
      return true;
    }

    return canAccessOutlet(outletId);
  }

  bool canAccessMenuItem(TenantAdminMenuItem menuItem) {
    return menuItem.visible &&
        canShowAction(menuItem.featureCode, menuItem.permissionCode);
  }
}
