class UserWidgetPermissionConfig {
  const UserWidgetPermissionConfig({
    required this.id,
    this.permission,
    this.permissionsAny = const [],
  });

  final String id;
  final String? permission;
  final List<String> permissionsAny;
}

bool userWidgetAllowed(
  UserWidgetPermissionConfig config,
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

List<T> filterUserConfigs<T extends UserWidgetPermissionConfig>(
  List<T> configs,
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return configs
      .where((config) => userWidgetAllowed(config, can, canAny))
      .toList(growable: false);
}
