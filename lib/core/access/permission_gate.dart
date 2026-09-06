import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'effective_permission_set.dart';
import 'permission_access_providers.dart';

enum _PermissionGateMode { single, any, all }

/// Fail-closed permission visibility gate.
///
/// Denied → [fallback] (default [SizedBox.shrink]) — no layout gap.
/// Does not evaluate business-state enable/disable; callers do that on the child.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    super.key,
    required String permission,
    required this.child,
    this.fallback,
  })  : _mode = _PermissionGateMode.single,
        _permissions = null,
        _permission = permission;

  const PermissionGate._({
    super.key,
    required _PermissionGateMode mode,
    required List<String> permissions,
    required this.child,
    this.fallback,
  })  : _mode = mode,
        _permissions = permissions,
        _permission = null;

  factory PermissionGate.any({
    Key? key,
    required List<String> permissions,
    required Widget child,
    Widget? fallback,
  }) {
    return PermissionGate._(
      key: key,
      mode: _PermissionGateMode.any,
      permissions: permissions,
      fallback: fallback,
      child: child,
    );
  }

  factory PermissionGate.all({
    Key? key,
    required List<String> permissions,
    required Widget child,
    Widget? fallback,
  }) {
    return PermissionGate._(
      key: key,
      mode: _PermissionGateMode.all,
      permissions: permissions,
      fallback: fallback,
      child: child,
    );
  }

  final _PermissionGateMode _mode;
  final String? _permission;
  final List<String>? _permissions;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final set = ref.watch(effectivePermissionSetProvider);
    final allowed = _isAllowed(set);
    if (!allowed) {
      return fallback ?? const SizedBox.shrink();
    }
    return child;
  }

  bool _isAllowed(EffectivePermissionSet set) {
    switch (_mode) {
      case _PermissionGateMode.single:
        return set.hasPermission(_permission!);
      case _PermissionGateMode.any:
        return set.hasAnyPermission(_permissions!);
      case _PermissionGateMode.all:
        return set.hasAllPermissions(_permissions!);
    }
  }
}
