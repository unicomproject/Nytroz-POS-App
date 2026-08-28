class TenantUser {
  const TenantUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.roleId,
    required this.roleName,
    this.roleDescription,
    required this.outletName,
    this.outlets = const [],
    this.outletCount,
    required this.status,
    this.lastActiveAt,
    this.profileImageUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? roleId;
  final String roleName;
  final String? roleDescription;
  final String outletName;
  final List<UserOutletOption> outlets;
  final int? outletCount;
  final String status;
  final DateTime? lastActiveAt;
  final String? profileImageUrl;
}

class TenantUserListResult {
  const TenantUserListResult({
    required this.items,
    this.page = 1,
    this.pageSize = 5,
    this.totalCount = 0,
  });

  final List<TenantUser> items;
  final int page;
  final int pageSize;
  final int totalCount;

  int get totalPages {
    if (pageSize <= 0 || totalCount <= 0) {
      return totalCount > 0 ? 1 : 0;
    }

    return (totalCount / pageSize).ceil();
  }

  int get rangeStart {
    if (totalCount == 0) {
      return 0;
    }

    return ((page - 1) * pageSize) + 1;
  }

  int get rangeEnd {
    if (totalCount == 0) {
      return 0;
    }

    return (page * pageSize).clamp(0, totalCount);
  }
}

class TenantUserListQuery {
  const TenantUserListQuery({
    this.search,
    this.page = 1,
    this.pageSize = 5,
    this.status,
    this.roleId,
    this.outletId,
    this.sortBy = 'name',
    this.sortDirection = 'asc',
  });

  final String? search;
  final int page;
  final int pageSize;
  final String? status;
  final String? roleId;
  final String? outletId;
  final String sortBy;
  final String sortDirection;
}

class RoleOption {
  const RoleOption({
    required this.id,
    required this.name,
    required this.code,
    this.roleDescription,
  });

  final String id;
  final String name;
  final String code;
  final String? roleDescription;
}

class UserOutletOption {
  const UserOutletOption({
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

class PermissionItem {
  const PermissionItem({
    required this.id,
    required this.code,
    required this.actionType,
    this.description,
  });

  final String id;
  final String code;
  final String actionType;
  final String? description;
}

class PermissionGroup {
  const PermissionGroup({
    required this.groupName,
    required this.permissions,
  });

  final String groupName;
  final List<PermissionItem> permissions;
}

class TenantUserCreateOptions {
  const TenantUserCreateOptions({
    required this.roles,
    required this.outlets,
    required this.permissionGroups,
  });

  final List<RoleOption> roles;
  final List<UserOutletOption> outlets;
  final List<PermissionGroup> permissionGroups;
}

class TenantUserDetail {
  const TenantUserDetail({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.employeeId,
    this.staffCode,
    this.roleId,
    required this.roleName,
    this.roleDescription,
    required this.outlets,
    this.outletCount,
    this.accessSummary,
    required this.status,
    required this.permissionOverrideEnabled,
    required this.overriddenPermissionIds,
    this.lastActiveAt,
    this.createdAt,
    this.profileImageUrl,
    this.profileMediaAssetId,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? employeeId;
  final String? staffCode;
  final String? roleId;
  final String roleName;
  final String? roleDescription;
  final List<UserOutletOption> outlets;
  final int? outletCount;
  final TenantUserAccessSummary? accessSummary;
  final String status;
  final bool permissionOverrideEnabled;
  final List<String> overriddenPermissionIds;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;
  final String? profileImageUrl;
  final String? profileMediaAssetId;
}

class TenantUserAccessSummary {
  const TenantUserAccessSummary({
    required this.outletCount,
    required this.moduleCount,
    required this.permissionCount,
  });

  final int outletCount;
  final int moduleCount;
  final int permissionCount;
}

class UserFormData {
  const UserFormData({
    required this.fullName,
    required this.email,
    this.phone,
    this.employeeId,
    required this.roleId,
    this.outletIds = const [],
    this.permissionOverrideEnabled = false,
    this.overriddenPermissionIds = const [],
    this.sendInviteEmail = false,
    this.status,
    this.profileImageFileName,
    this.profileMediaAssetId,
  });

  final String fullName;
  final String email;
  final String? phone;
  final String? employeeId;
  final String roleId;
  final List<String> outletIds;
  final bool permissionOverrideEnabled;
  final List<String> overriddenPermissionIds;
  final bool sendInviteEmail;
  final String? status;
  final String? profileImageFileName;
  final String? profileMediaAssetId;
}
