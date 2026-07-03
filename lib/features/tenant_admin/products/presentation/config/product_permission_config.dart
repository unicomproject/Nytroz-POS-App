class ProductWidgetPermissionConfig {
  const ProductWidgetPermissionConfig({
    required this.id,
    this.permission,
    this.permissionsAny = const [],
    this.legacyIds = const [],
    this.showInMoreMenu = false,
  });

  final String id;
  final String? permission;
  final List<String> permissionsAny;
  final List<String> legacyIds;
  final bool showInMoreMenu;

  bool matchesKey(String key) {
    return id == key || legacyIds.contains(key);
  }
}

bool productWidgetAllowed(
  ProductWidgetPermissionConfig config,
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  if (config.permission == null && config.permissionsAny.isEmpty) {
    return true;
  }

  if (config.permission != null && can(config.permission!)) {
    return true;
  }

  if (config.permissionsAny.isNotEmpty && canAny(config.permissionsAny)) {
    return true;
  }

  return false;
}

List<T> filterProductConfigs<T extends ProductWidgetPermissionConfig>(
  List<T> configs,
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return configs
      .where((config) => productWidgetAllowed(config, can, canAny))
      .toList(growable: false);
}
