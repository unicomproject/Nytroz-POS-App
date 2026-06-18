class OutletWidgetPermissionConfig {
  const OutletWidgetPermissionConfig({
    required this.id,
    this.permission,
    this.permissionsAny = const [],
    this.legacyIds = const [],
  });

  final String id;
  final String? permission;
  final List<String> permissionsAny;
  final List<String> legacyIds;

  bool matchesKey(String key) {
    return id == key || legacyIds.contains(key);
  }
}

bool outletWidgetAllowed(
  OutletWidgetPermissionConfig config,
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  if (config.permission != null && can(config.permission!)) {
    return true;
  }

  if (config.permissionsAny.isNotEmpty && canAny(config.permissionsAny)) {
    return true;
  }

  return false;
}

OutletWidgetPermissionConfig? findOutletWidgetConfig(
  String key,
  List<OutletWidgetPermissionConfig> configs,
) {
  for (final config in configs) {
    if (config.matchesKey(key)) {
      return config;
    }
  }

  return null;
}

List<T> filterOutletConfigs<T extends OutletWidgetPermissionConfig>(
  List<T> configs,
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return configs
      .where((config) => outletWidgetAllowed(config, can, canAny))
      .toList(growable: false);
}
