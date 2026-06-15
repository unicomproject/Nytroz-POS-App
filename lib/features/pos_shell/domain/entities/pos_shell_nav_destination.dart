import 'package:flutter/material.dart';

class PosShellNavDestination {
  const PosShellNavDestination({
    required this.key,
    required this.label,
    required this.icon,
    this.routePath,
    this.permissionKey,
    this.anyOfPermissionKeys = const [],
    this.routeExists = false,
    this.unavailableMessage,
  });

  final String key;
  final String label;
  final IconData icon;
  final String? routePath;
  final String? permissionKey;
  final List<String> anyOfPermissionKeys;
  final bool routeExists;
  final String? unavailableMessage;

  bool isVisible(Set<String> grantedPermissions) {
    if (anyOfPermissionKeys.isNotEmpty) {
      return anyOfPermissionKeys.any(grantedPermissions.contains);
    }

    return grantedPermissions.contains(permissionKey);
  }

  bool isEnabled(Set<String> grantedPermissions) {
    return isVisible(grantedPermissions) && routeExists && routePath != null;
  }
}
