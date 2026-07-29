class TenantAdminMenuItem {
  const TenantAdminMenuItem({
    required this.key,
    required this.label,
    required this.route,
    required this.iconKey,
    required this.featureCode,
    required this.permissionCode,
    required this.visible,
    required this.order,
    this.isRouteAvailable = true,
    this.unavailableMessage = 'This module is not available yet.',
  });

  final String key;
  final String label;
  final String route;
  final String iconKey;
  final String featureCode;
  final String permissionCode;
  final bool visible;
  final int order;

  /// When false, the item is shown disabled and must not navigate.
  final bool isRouteAvailable;
  final String unavailableMessage;
}
