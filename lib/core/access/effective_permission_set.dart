import 'dart:collection';

/// Immutable, membership-only effective permission set.
///
/// Backend (Chunk 5) is authoritative. This type never expands parents,
/// never applies entitlements, and never invents grants.
class EffectivePermissionSet {
  EffectivePermissionSet._(this._codes);

  /// Empty fail-closed set (no grants).
  static final EffectivePermissionSet empty = EffectivePermissionSet._(
    Set<String>.unmodifiable(const <String>{}),
  );

  final Set<String> _codes;

  /// Normalizes [codes]: trim, drop empties, dedupe. Does not expand hierarchy.
  factory EffectivePermissionSet.fromIterable(Iterable<String>? codes) {
    if (codes == null) {
      return empty;
    }

    final normalized = <String>{};
    for (final raw in codes) {
      final code = raw.trim();
      if (code.isEmpty) {
        continue;
      }
      normalized.add(code);
    }

    if (normalized.isEmpty) {
      return empty;
    }

    return EffectivePermissionSet._(Set<String>.unmodifiable(normalized));
  }

  /// Ordered unique list for session persistence / AuthSession storage.
  static List<String> normalizeToList(Iterable<String>? codes) {
    return EffectivePermissionSet.fromIterable(codes).toList();
  }

  bool get isEmpty => _codes.isEmpty;

  bool get isNotEmpty => _codes.isNotEmpty;

  int get length => _codes.length;

  /// Exact-code membership. Fail-closed for empty, wildcard, or slash/shorthand.
  bool hasPermission(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (_isUnsupportedLookup(trimmed)) {
      return false;
    }
    return _codes.contains(trimmed);
  }

  bool hasAllPermissions(Iterable<String> codes) {
    for (final code in codes) {
      if (!hasPermission(code)) {
        return false;
      }
    }
    return true;
  }

  bool hasAnyPermission(Iterable<String> codes) {
    for (final code in codes) {
      if (hasPermission(code)) {
        return true;
      }
    }
    return false;
  }

  UnmodifiableSetView<String> get codes => UnmodifiableSetView(_codes);

  List<String> toList() => _codes.toList(growable: false);

  /// Returns items whose [permissionOf] is present in this set.
  /// Denied items are omitted (no placeholder gaps for callers to layout).
  List<T> filterByPermission<T>(
    Iterable<T> items,
    String? Function(T item) permissionOf,
  ) {
    final visible = <T>[];
    for (final item in items) {
      final code = permissionOf(item);
      if (code == null || code.trim().isEmpty) {
        continue;
      }
      if (hasPermission(code)) {
        visible.add(item);
      }
    }
    return List<T>.unmodifiable(visible);
  }

  static bool _isUnsupportedLookup(String code) {
    // No wildcards, no slash/shorthand compound lookups.
    return code.contains('*') || code.contains('/');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! EffectivePermissionSet) {
      return false;
    }
    if (other._codes.length != _codes.length) {
      return false;
    }
    return _codes.containsAll(other._codes);
  }

  @override
  int get hashCode => Object.hashAllUnordered(_codes);
}
