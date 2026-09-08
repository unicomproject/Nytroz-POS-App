class TenantUser {
  const TenantUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.staffCode,
    this.profileImageUrl,
    this.roleId,
    required this.roleName,
    this.roleDescription,
    required this.outletName,
    this.outlets = const [],
    this.outletCount,
    required this.status,
    this.lastActiveAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? staffCode;
  final String? profileImageUrl;
  final String? roleId;
  final String roleName;
  final String? roleDescription;
  final String outletName;
  final List<UserOutletOption> outlets;
  final int? outletCount;
  final String status;
  final DateTime? lastActiveAt;
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
    this.isActive = true,
    this.moduleCount = 0,
    this.permissionCount = 0,
    this.modulePreview = const [],
    this.permissionPreview = const [],
  });

  final String id;
  final String name;
  final String code;
  final String? roleDescription;
  final bool isActive;
  final int moduleCount;
  final int permissionCount;
  final List<String> modulePreview;
  final List<String> permissionPreview;
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
    this.name,
    this.moduleId,
    this.moduleCode,
    this.moduleName,
    this.sortOrder = 0,
    this.isAssignable = true,
    this.isLocked = false,
  });

  final String id;
  final String code;
  final String actionType;
  final String? description;
  final String? name;
  final String? moduleId;
  final String? moduleCode;
  final String? moduleName;
  final int sortOrder;
  final bool isAssignable;
  final bool isLocked;

  String get displayName {
    final value = name?.trim();
    if (value != null && value.isNotEmpty) return value;
    if (actionType.trim().isNotEmpty) {
      return actionType
          .trim()
          .split(RegExp(r'[_\s]+'))
          .where((part) => part.isNotEmpty)
          .map((part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
          .join(' ');
    }
    return code;
  }
}

class PermissionGroup {
  const PermissionGroup({
    required this.groupName,
    required this.permissions,
    this.moduleId,
    this.moduleCode,
    this.description,
    this.sortOrder = 0,
  });

  final String groupName;
  final List<PermissionItem> permissions;
  final String? moduleId;
  final String? moduleCode;
  final String? description;
  final int sortOrder;
}

class UserTillOption {
  const UserTillOption({
    required this.id,
    required this.outletId,
    required this.name,
    required this.code,
    required this.status,
  });

  final String id;
  final String outletId;
  final String name;
  final String code;
  final String status;
}

class TenantUserCreateCapabilities {
  const TenantUserCreateCapabilities({
    this.supportsInvitedUserCreation = false,
    this.supportsDirectActiveCreation = false,
    this.supportsUserPermissionOverrides = false,
    this.supportsPermissionDenies = false,
    this.supportsAllOutletAccess = false,
    this.supportsNoOutletAccess = false,
    this.supportsExplicitTillAccess = false,
    this.supportsDefaultOutlet = false,
    this.supportsDefaultTill = false,
    this.supportsAccessStartDate = false,
    this.supportsTemporaryPassword = false,
    this.supportsForcePasswordChange = false,
    this.supportsTwoFactorDuringCreation = false,
    this.supportsSaveDraft = false,
  });

  final bool supportsInvitedUserCreation;
  final bool supportsDirectActiveCreation;
  final bool supportsUserPermissionOverrides;
  final bool supportsPermissionDenies;
  final bool supportsAllOutletAccess;
  final bool supportsNoOutletAccess;
  final bool supportsExplicitTillAccess;
  final bool supportsDefaultOutlet;
  final bool supportsDefaultTill;
  final bool supportsAccessStartDate;
  final bool supportsTemporaryPassword;
  final bool supportsForcePasswordChange;
  final bool supportsTwoFactorDuringCreation;
  final bool supportsSaveDraft;
}

class TenantUserCreateOptions {
  const TenantUserCreateOptions({
    required this.roles,
    required this.outlets,
    required this.permissionGroups,
    this.supportedStatuses = const [],
    this.tills = const [],
    this.supportedOutletAccessScopes = const [],
    this.supportedTillAccessScopes = const [],
    this.capabilities = const TenantUserCreateCapabilities(),
    this.permissionCatalogVersion,
  });

  final List<RoleOption> roles;
  final List<UserOutletOption> outlets;
  final List<PermissionGroup> permissionGroups;
  final List<String> supportedStatuses;
  final List<UserTillOption> tills;
  final List<String> supportedOutletAccessScopes;
  final List<String> supportedTillAccessScopes;
  final TenantUserCreateCapabilities capabilities;
  final String? permissionCatalogVersion;
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
    this.profileMediaAction,
    this.outletAccessScope = 'ALL_OUTLETS',
    this.defaultOutletId,
    this.tillAccessScope = 'ALL_ACCESSIBLE_TILLS',
    this.tillIds = const [],
    this.defaultTillId,
    this.permissionCatalogVersion,
    this.deniedPermissionIds = const [],
    this.password,
    this.confirmPassword,
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
  final String? profileMediaAction;
  final String outletAccessScope;
  final String? defaultOutletId;
  final String tillAccessScope;
  final List<String> tillIds;
  final String? defaultTillId;
  final String? permissionCatalogVersion;
  final List<String> deniedPermissionIds;
  final String? password;
  final String? confirmPassword;
}
