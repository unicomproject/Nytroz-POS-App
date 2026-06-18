class TenantAdminContextException implements Exception {
  const TenantAdminContextException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => 'TenantAdminContextException($code): $message';
}

class TenantAdminContextErrorCodes {
  const TenantAdminContextErrorCodes._();

  static const authRequired = 'AUTH_REQUIRED';
  static const accessDenied = 'ACCESS_DENIED';
  static const loadFailed = 'LOAD_FAILED';
}
