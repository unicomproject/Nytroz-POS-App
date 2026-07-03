class PermissionCatalog {
  const PermissionCatalog({
    required this.modules,
  });

  final List<PermissionCatalogModule> modules;
}

class PermissionCatalogModule {
  const PermissionCatalogModule({
    required this.id,
    required this.code,
    required this.name,
    required this.scope,
    required this.sortOrder,
    required this.isActive,
    required this.features,
    this.description,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final String scope;
  final int sortOrder;
  final bool isActive;
  final List<PermissionCatalogFeature> features;
}

class PermissionCatalogFeature {
  const PermissionCatalogFeature({
    required this.id,
    required this.code,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    required this.permissions,
    this.description,
    this.entitlementKey,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final String? entitlementKey;
  final int sortOrder;
  final bool isActive;
  final List<PermissionCatalogPermission> permissions;
}

class PermissionCatalogPermission {
  const PermissionCatalogPermission({
    required this.id,
    required this.code,
    required this.name,
    required this.scope,
    required this.sortOrder,
    required this.isActive,
    required this.source,
    this.description,
    this.action,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final String? action;
  final String scope;
  final int sortOrder;
  final bool isActive;
  final String source;
}
