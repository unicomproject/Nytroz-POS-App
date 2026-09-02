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

  bool startsWithAny(String code, List<String> prefixes) =>
      prefixes.any(code.startsWith);

  final canAccessTenantAdmin = permissions.any(
    (code) =>
        (startsWithAny(code, const ['tenant.', 'tenant_admin.']) &&
            code != 'tenant.till.manage') ||
        code == 'dashboard.view' ||
        startsWithAny(code, const [
          'dashboard.',
          'outlet.',
          'user.',
          'role.',
          'permission.',
          'product.',
          'inventory.',
          'report.',
          'billing.',
          'subscription.',
          'tenant_settings.',
          'activity_log.',
        ]),
  );

  final canAccessPos = permissions.any(
    (code) =>
        startsWithAny(code, const [
          'pos.',
          'sales.',
          'payments.',
          'receipts.',
          'orders.',
          'customers.',
          'returns.',
          'refunds.',
          'exchanges.',
          'cash_drawer.',
          'till.',
          'notifications.',
        ]) ||
        code == 'products.view' ||
        code == 'products.search',
  );

  return WorkspaceAccess(
    canAccessTenantAdmin: canAccessTenantAdmin,
    canAccessPos: canAccessPos,
  );
}
