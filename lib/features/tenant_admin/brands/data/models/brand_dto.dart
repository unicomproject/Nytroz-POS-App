class BrandDto {
  const BrandDto({
    required this.id,
    required this.brandCode,
    required this.brandName,
    required this.status,
    this.description,
    this.logoUrl,
    this.logoMediaAssetId,
    this.sortOrder = 0,
    this.productCount = 0,
    this.createdAt,
    this.updatedAt,
    this.rowVersion = 1,
  });

  factory BrandDto.fromJson(Map<String, dynamic> json) {
    return BrandDto(
      id: json['id']?.toString() ?? '',
      brandCode: json['brandCode']?.toString() ?? '',
      brandName:
          json['brandName']?.toString() ?? json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      description: json['description']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      logoMediaAssetId: json['logoMediaAssetId']?.toString(),
      sortOrder: _readInt(json['sortOrder'], fallback: 0),
      productCount: _readInt(json['productCount'], fallback: 0),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      rowVersion: _readInt(json['rowVersion'], fallback: 1),
    );
  }

  final String id;
  final String brandCode;
  final String brandName;
  final String status;
  final String? description;
  final String? logoUrl;
  final String? logoMediaAssetId;
  final int sortOrder;
  final int productCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int rowVersion;

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
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
    this.sortOrder = 0,
    this.expectedRowVersion,
  });

  final String brandCode;
  final String name;
  final String status;
  final String? description;
  final String? brandSlug;
  final String? logoUrl;
  final int sortOrder;
  final int? expectedRowVersion;

  Map<String, dynamic> toJson() {
    return {
      'brandCode': brandCode,
      'name': name,
      'status': status,
      'sortOrder': sortOrder,
      if (expectedRowVersion != null) 'expectedRowVersion': expectedRowVersion,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      if (brandSlug != null && brandSlug!.trim().isNotEmpty)
        'brandSlug': brandSlug!.trim(),
      if (logoUrl != null && logoUrl!.trim().isNotEmpty)
        'logoUrl': logoUrl!.trim(),
    };
  }
}
