class RoleAssignment {
  const RoleAssignment({
    required this.userId,
    required this.scopeType,
    required this.outletIds,
    this.fullName,
    this.email,
  });

  final String userId;
  final RoleAccessScopeType scopeType;
  final List<String> outletIds;
  final String? fullName;
  final String? email;
}

enum RoleAccessScopeType {
  tenantWide,
  selectedOutlets;

  String get value {
    switch (this) {
      case RoleAccessScopeType.tenantWide:
        return 'TENANT_WIDE';
      case RoleAccessScopeType.selectedOutlets:
        return 'SELECTED_OUTLETS';
    }
  }

  static RoleAccessScopeType fromValue(String value) {
    if (value == 'SELECTED_OUTLETS') {
      return RoleAccessScopeType.selectedOutlets;
    }
    return RoleAccessScopeType.tenantWide;
  }
}
