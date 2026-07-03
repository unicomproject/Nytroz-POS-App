import '../../domain/entities/permission_catalog.dart';

List<PermissionCatalogModule> filterPermissionCatalog({
  required PermissionCatalog catalog,
  required String searchQuery,
  required String scopeFilter,
  required String? moduleFilter,
}) {
  final normalizedSearch = searchQuery.trim().toLowerCase();

  return catalog.modules
      .where((module) {
        if (moduleFilter != null &&
            moduleFilter.isNotEmpty &&
            module.code != moduleFilter) {
          return false;
        }

        return true;
      })
      .map((module) {
        final features = module.features
            .map((feature) {
              final permissions = feature.permissions.where((permission) {
                if (scopeFilter.isNotEmpty && permission.scope != scopeFilter) {
                  return false;
                }

                if (normalizedSearch.isEmpty) {
                  return true;
                }

                return _matchesSearch(
                  permission,
                  feature,
                  module,
                  normalizedSearch,
                );
              }).toList(growable: false);

              if (permissions.isEmpty) {
                return null;
              }

              return PermissionCatalogFeature(
                id: feature.id,
                code: feature.code,
                name: feature.name,
                description: feature.description,
                entitlementKey: feature.entitlementKey,
                sortOrder: feature.sortOrder,
                isActive: feature.isActive,
                permissions: permissions,
              );
            })
            .whereType<PermissionCatalogFeature>()
            .toList(growable: false);

        if (features.isEmpty) {
          return null;
        }

        return PermissionCatalogModule(
          id: module.id,
          code: module.code,
          name: module.name,
          description: module.description,
          scope: module.scope,
          sortOrder: module.sortOrder,
          isActive: module.isActive,
          features: features,
        );
      })
      .whereType<PermissionCatalogModule>()
      .toList(growable: false);
}

bool _matchesSearch(
  PermissionCatalogPermission permission,
  PermissionCatalogFeature feature,
  PermissionCatalogModule module,
  String search,
) {
  return [
    permission.code,
    permission.name,
    permission.description ?? '',
    feature.code,
    feature.name,
    module.code,
    module.name,
  ].any((value) => value.toLowerCase().contains(search));
}

int countPermissions(Iterable<PermissionCatalogModule> modules) {
  var total = 0;
  for (final module in modules) {
    for (final feature in module.features) {
      total += feature.permissions.length;
    }
  }

  return total;
}
