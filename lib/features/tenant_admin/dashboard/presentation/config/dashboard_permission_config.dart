class DashboardWidgetPermissionConfig {
  const DashboardWidgetPermissionConfig({
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

bool dashboardWidgetAllowed(
  DashboardWidgetPermissionConfig config,
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

DashboardWidgetPermissionConfig? findDashboardWidgetConfig(
  String key,
  List<DashboardWidgetPermissionConfig> configs,
) {
  for (final config in configs) {
    if (config.matchesKey(key)) {
      return config;
    }
  }

  return null;
}
