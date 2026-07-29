class BrandDto {
  const BrandDto({
    required this.id,
    required this.brandCode,
    required this.brandName,
    required this.status,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory BrandDto.fromJson(Map<String, dynamic> json) {
    return BrandDto(
      id: json['id']?.toString() ?? '',
      brandCode: json['brandCode']?.toString() ?? '',
      brandName:
          json['brandName']?.toString() ?? json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      description: json['description']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  final String id;
  final String brandCode;
  final String brandName;
  final String status;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}

class BrandListResultDto {
  const BrandListResultDto({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  factory BrandListResultDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => BrandDto.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : <BrandDto>[];

    return BrandListResultDto(
      items: items,
      pageNumber: _readInt(json['pageNumber'], fallback: 1),
      pageSize: _readInt(json['pageSize'], fallback: items.length),
      totalCount: _readInt(json['totalCount'], fallback: items.length),
    );
  }

  final List<BrandDto> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class BrandUpsertRequestDto {
  const BrandUpsertRequestDto({
    required this.brandCode,
    required this.name,
    required this.status,
    this.description,
    this.brandSlug,
    this.logoUrl,
  });

  final String brandCode;
  final String name;
  final String status;
  final String? description;
  final String? brandSlug;
  final String? logoUrl;

  Map<String, dynamic> toJson() {
    return {
      'brandCode': brandCode,
      'name': name,
      'status': status,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      if (brandSlug != null && brandSlug!.trim().isNotEmpty)
        'brandSlug': brandSlug!.trim(),
      if (logoUrl != null && logoUrl!.trim().isNotEmpty)
        'logoUrl': logoUrl!.trim(),
    };
  }
}
