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
  });

  final String key;
  final String label;
  final String route;
  final String iconKey;
  final String featureCode;
  final String permissionCode;
  final bool visible;
  final int order;
}
