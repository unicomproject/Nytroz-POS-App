import '../../../../core/access/effective_permission_set.dart';
import '../../../../core/access/pos_access_codes.dart';
import '../../../../core/access/tenant_admin_access_codes.dart';
import '../utils/jwt_expiry.dart';
import '../utils/jwt_permissions.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.userId,
    required this.userDisplayName,
    this.permissionCodes = const [],
    this.refreshToken,
    this.refreshTokenExpiresAt,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? refreshTokenExpiresAt;
  final String userId;
  final String userDisplayName;

  /// Backend effective permission codes (Chunk 5). Treat as read-only.
  /// Prefer [effectivePermissions] / `effectivePermissionSetProvider` for checks.
  final List<String> permissionCodes;
  final DateTime? expiresAt;

  /// Immutable Set-backed membership view of [permissionCodes].
  EffectivePermissionSet get effectivePermissions =>
      EffectivePermissionSet.fromIterable(permissionCodes);

  DateTime? get effectiveExpiresAt => expiresAt ?? readJwtExpiry(accessToken);

  bool get isExpired {
    final expiry = effectiveExpiresAt;
    if (expiry == null) {
      return false;
    }

    return DateTime.now().toUtc().isAfter(expiry.toUtc());
  }

  bool get canRefresh {
    final token = refreshToken;
    if (token == null || token.isEmpty) {
      return false;
    }
    final expiry = refreshTokenExpiresAt;
    return expiry == null || DateTime.now().toUtc().isBefore(expiry.toUtc());
  }

  bool get isAuthenticated =>
      accessToken.isNotEmpty && (!isExpired || canRefresh);

  /// Exact effective-code membership. No parent expand / wildcards / role checks.
  bool hasPermission(String permissionCode) {
    return effectivePermissions.hasPermission(permissionCode);
  }

  bool hasAllPermissions(Iterable<String> codes) =>
      effectivePermissions.hasAllPermissions(codes);

  bool hasAnyPermission(Iterable<String> codes) =>
      effectivePermissions.hasAnyPermission(codes);

  bool get canOpenPosTill => hasPermission(PosPermissionCodes.openTill);

  bool get canActivatePosDevice =>
      canOpenPosTill || hasPermission('tenant.till.manage');

  bool get canAccessTenantAdminDashboard {
    const dashboardCodes = [
      TenantAdminPermissionCodes.tenantContextView,
      TenantAdminPermissionCodes.dashboardView,
      TenantAdminPermissionCodes.tenantDashboardView,
      'tenant.dashboard.view',
      'dashboard.view',
      'tenant_admin.dashboard.view',
    ];

    return hasAnyPermission(dashboardCodes);
  }

  bool get requiresPosDeviceBootstrap => canActivatePosDevice || canOpenPosTill;

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'refreshTokenExpiresAt': refreshTokenExpiresAt?.toIso8601String(),
      'userId': userId,
      'userDisplayName': userDisplayName,
      'permissionCodes': permissionCodes,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
      refreshTokenExpiresAt: DateTime.tryParse(
        json['refreshTokenExpiresAt']?.toString() ?? '',
      ),
      userId: json['userId'] as String? ?? '',
      userDisplayName: json['userDisplayName'] as String? ?? '',
      permissionCodes: EffectivePermissionSet.normalizeToList(
        _resolveStoredPermissionCodes(
          accessToken: json['accessToken'] as String? ?? '',
          storedCodes: _stringList(json['permissionCodes']),
        ),
      ),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
    );
  }
}

List<String> _resolveStoredPermissionCodes({
  required String accessToken,
  required List<String> storedCodes,
}) {
  if (storedCodes.isNotEmpty) {
    return storedCodes;
  }

  if (accessToken.isEmpty) {
    return storedCodes;
  }

  return readJwtPermissionCodes(accessToken);
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return value
        .map((item) {
          if (item is Map) {
            return item['permissionCode']?.toString() ??
                item['PermissionCode']?.toString() ??
                item['code']?.toString() ??
                item['Code']?.toString() ??
                '';
          }
          return item.toString();
        })
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  return const [];
}
