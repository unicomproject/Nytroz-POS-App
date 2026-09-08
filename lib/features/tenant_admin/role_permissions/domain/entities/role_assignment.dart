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

class RoleAssignmentOptions {
  const RoleAssignmentOptions({
    required this.users,
    required this.outlets,
    required this.canAssignUsers,
    required this.canAssignOutlets,
  });

  final List<RoleAssignmentUserOption> users;
  final List<RoleAssignmentOutletOption> outlets;
  final bool canAssignUsers;
  final bool canAssignOutlets;
}

class RoleAssignmentUserOption {
  const RoleAssignmentUserOption({
    required this.id,
    required this.fullName,
    required this.email,
    this.staffCode,
    required this.status,
  });

  final String id;
  final String fullName;
  final String email;
  final String? staffCode;
  final String status;
}

class RoleAssignmentOutletOption {
  const RoleAssignmentOutletOption({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
  });

  final String id;
  final String name;
  final String code;
  final String status;
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
