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
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final String userId;
  final String userDisplayName;
  final List<String> permissionCodes;
  final DateTime? expiresAt;

  DateTime? get effectiveExpiresAt => expiresAt ?? readJwtExpiry(accessToken);

  bool get isExpired {
    final expiry = effectiveExpiresAt;
    if (expiry == null) {
      return false;
    }

    return DateTime.now().toUtc().isAfter(expiry.toUtc());
  }

  bool get isAuthenticated => accessToken.isNotEmpty && !isExpired;

  bool hasPermission(String permissionCode) {
    return permissionCodes.contains(permissionCode);
  }

  bool get canOpenPosTill => hasPermission(PosPermissionCodes.openTill);

  bool get canActivatePosDevice =>
      canOpenPosTill || hasPermission('tenant.till.manage');

  bool get canAccessTenantAdminDashboard {
    const dashboardCodes = [
      TenantAdminPermissionCodes.tenantContextView,
      TenantAdminPermissionCodes.dashboardView,
      TenantAdminPermissionCodes.tenantDashboardView,
      'dashboard.view',
      'tenant_admin.dashboard.view',
    ];

    return dashboardCodes.any(hasPermission);
  }

  bool get requiresPosDeviceBootstrap => canActivatePosDevice || canOpenPosTill;

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
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
      userId: json['userId'] as String? ?? '',
      userDisplayName: json['userDisplayName'] as String? ?? '',
      permissionCodes: _resolveStoredPermissionCodes(
        accessToken: json['accessToken'] as String? ?? '',
        storedCodes: _stringList(json['permissionCodes']),
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
