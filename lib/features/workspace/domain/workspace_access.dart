enum AppWorkspace {
  tenantAdmin,
  pos,
}

class WorkspaceAccess {
  const WorkspaceAccess({
    required this.canAccessTenantAdmin,
    required this.canAccessPos,
  });

  final bool canAccessTenantAdmin;
  final bool canAccessPos;

  bool get hasAny => canAccessTenantAdmin || canAccessPos;
  bool get hasMultiple => canAccessTenantAdmin && canAccessPos;

  AppWorkspace? get onlyWorkspace {
    if (hasMultiple || !hasAny) return null;
    return canAccessTenantAdmin ? AppWorkspace.tenantAdmin : AppWorkspace.pos;
  }

  bool allows(AppWorkspace workspace) => switch (workspace) {
        AppWorkspace.tenantAdmin => canAccessTenantAdmin,
        AppWorkspace.pos => canAccessPos,
      };
}

WorkspaceAccess resolveWorkspaceAccess(Iterable<String> permissionCodes) {
  final permissions = permissionCodes
      .map((code) => code.trim().toLowerCase())
      .where((code) => code.isNotEmpty)
      .toSet();

  final canAccessTenantAdmin =
      permissions.contains('workspace.tenant_admin.access');
  final canAccessPos = permissions.contains('workspace.pos.access');

  return WorkspaceAccess(
    canAccessTenantAdmin: canAccessTenantAdmin,
    canAccessPos: canAccessPos,
  );
}
