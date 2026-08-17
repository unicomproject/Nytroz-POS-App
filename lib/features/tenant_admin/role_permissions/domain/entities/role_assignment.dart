class RoleAssignment {
  const RoleAssignment({
    required this.userId,
    required this.scopeType,
    required this.outletIds,
  });

  final String userId;
  final RoleAccessScopeType scopeType;
  final List<String> outletIds;
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
