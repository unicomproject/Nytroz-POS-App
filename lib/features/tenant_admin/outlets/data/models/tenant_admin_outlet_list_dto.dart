class TenantAdminOutletListItemDto {
  const TenantAdminOutletListItemDto({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.status,
    this.imageUrl,
    this.manager,
    this.tills,
    this.operationalHealth,
    this.location,
    required this.access,
  });

  factory TenantAdminOutletListItemDto.fromJson(Map<String, dynamic> json) {
    return TenantAdminOutletListItemDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      manager: json['manager'] != null
          ? TenantAdminOutletManagerPreviewDto.fromJson(
              json['manager'] as Map<String, dynamic>)
          : null,
      tills: json['tills'] != null
          ? TenantAdminOutletTillPreviewDto.fromJson(
              json['tills'] as Map<String, dynamic>)
          : null,
      operationalHealth: json['operationalHealth'] != null
          ? TenantAdminOutletHealthPreviewDto.fromJson(
              json['operationalHealth'] as Map<String, dynamic>)
          : null,
      location: json['location'] != null
          ? TenantAdminOutletLocationPreviewDto.fromJson(
              json['location'] as Map<String, dynamic>)
          : null,
      access: TenantAdminOutletListSectionAccessDto.fromJson(
          json['access'] as Map<String, dynamic>? ?? {}),
    );
  }

  final String id;
  final String name;
  final String code;
  final String type;
  final String status;
  final String? imageUrl;
  final TenantAdminOutletManagerPreviewDto? manager;
  final TenantAdminOutletTillPreviewDto? tills;
  final TenantAdminOutletHealthPreviewDto? operationalHealth;
  final TenantAdminOutletLocationPreviewDto? location;
  final TenantAdminOutletListSectionAccessDto access;
}

class TenantAdminOutletManagerPreviewDto {
  const TenantAdminOutletManagerPreviewDto({
    required this.tenantUserId,
    this.displayName,
    this.avatarUrl,
  });

  factory TenantAdminOutletManagerPreviewDto.fromJson(
      Map<String, dynamic> json) {
    return TenantAdminOutletManagerPreviewDto(
      tenantUserId: json['tenantUserId'] as String? ?? '',
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String tenantUserId;
  final String? displayName;
  final String? avatarUrl;
}

class TenantAdminOutletTillPreviewDto {
  const TenantAdminOutletTillPreviewDto({
    required this.totalCount,
    required this.activeCount,
    required this.onlineCount,
  });

  factory TenantAdminOutletTillPreviewDto.fromJson(Map<String, dynamic> json) {
    return TenantAdminOutletTillPreviewDto(
      totalCount: json['totalCount'] as int? ?? 0,
      activeCount: json['activeCount'] as int? ?? 0,
      onlineCount: json['onlineCount'] as int? ?? 0,
    );
  }

  final int totalCount;
  final int activeCount;
  final int onlineCount;
}

class TenantAdminOutletHealthPreviewDto {
  const TenantAdminOutletHealthPreviewDto({
    required this.status,
    required this.activeAlertCount,
  });

  factory TenantAdminOutletHealthPreviewDto.fromJson(
      Map<String, dynamic> json) {
    return TenantAdminOutletHealthPreviewDto(
      status: json['status'] as String? ?? '',
      activeAlertCount: json['activeAlertCount'] as int? ?? 0,
    );
  }

  final String status;
  final int activeAlertCount;
}

class TenantAdminOutletLocationPreviewDto {
  const TenantAdminOutletLocationPreviewDto({
    this.addressLine,
    this.city,
    this.displayLocation,
  });

  factory TenantAdminOutletLocationPreviewDto.fromJson(
      Map<String, dynamic> json) {
    return TenantAdminOutletLocationPreviewDto(
      addressLine: json['addressLine'] as String?,
      city: json['city'] as String?,
      displayLocation: json['displayLocation'] as String?,
    );
  }

  final String? addressLine;
  final String? city;
  final String? displayLocation;
}

class TenantAdminOutletListSectionAccessDto {
  const TenantAdminOutletListSectionAccessDto({
    required this.canViewTillsAndHealth,
  });

  factory TenantAdminOutletListSectionAccessDto.fromJson(
      Map<String, dynamic> json) {
    return TenantAdminOutletListSectionAccessDto(
      canViewTillsAndHealth: json['canViewTillsAndHealth'] as bool? ?? false,
    );
  }

  final bool canViewTillsAndHealth;
}

class TenantAdminOutletListResponseDto {
  const TenantAdminOutletListResponseDto({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  factory TenantAdminOutletListResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) =>
            TenantAdminOutletListItemDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    return TenantAdminOutletListResponseDto(
      items: items,
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      totalCount: json['totalCount'] as int? ?? items.length,
    );
  }

  final List<TenantAdminOutletListItemDto> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
}
