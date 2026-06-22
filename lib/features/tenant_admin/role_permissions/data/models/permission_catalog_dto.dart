class PermissionCatalogDto {
  const PermissionCatalogDto({
    required this.modules,
  });

  factory PermissionCatalogDto.fromJson(Map<String, dynamic> json) {
    return PermissionCatalogDto(
      modules: _mapList(json['modules'], PermissionCatalogModuleDto.fromJson),
    );
  }

  final List<PermissionCatalogModuleDto> modules;
}

class PermissionCatalogModuleDto {
  const PermissionCatalogModuleDto({
    required this.id,
    required this.code,
    required this.name,
    required this.scope,
    required this.sortOrder,
    required this.isActive,
    required this.features,
    this.description,
  });

  factory PermissionCatalogModuleDto.fromJson(Map<String, dynamic> json) {
    return PermissionCatalogModuleDto(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      scope: json['scope'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      features: _mapList(json['features'], PermissionCatalogFeatureDto.fromJson),
    );
  }

  final String id;
  final String code;
  final String name;
  final String? description;
  final String scope;
  final int sortOrder;
  final bool isActive;
  final List<PermissionCatalogFeatureDto> features;
}

class PermissionCatalogFeatureDto {
  const PermissionCatalogFeatureDto({
    required this.id,
    required this.code,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    required this.permissions,
    this.description,
    this.entitlementKey,
  });

  factory PermissionCatalogFeatureDto.fromJson(Map<String, dynamic> json) {
    return PermissionCatalogFeatureDto(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      entitlementKey: json['entitlementKey'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      permissions: _mapList(
        json['permissions'],
        PermissionCatalogPermissionDto.fromJson,
      ),
    );
  }

  final String id;
  final String code;
  final String name;
  final String? description;
  final String? entitlementKey;
  final int sortOrder;
  final bool isActive;
  final List<PermissionCatalogPermissionDto> permissions;
}

class PermissionCatalogPermissionDto {
  const PermissionCatalogPermissionDto({
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

  factory PermissionCatalogPermissionDto.fromJson(Map<String, dynamic> json) {
    return PermissionCatalogPermissionDto(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      action: json['action'] as String?,
      scope: json['scope'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      source: json['source'] as String? ?? 'tenant',
    );
  }

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

List<T> _mapList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}
