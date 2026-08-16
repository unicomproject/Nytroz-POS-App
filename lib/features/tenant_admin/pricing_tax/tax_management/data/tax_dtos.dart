class TaxAggregateDto {
  const TaxAggregateDto({
    required this.id,
    required this.taxName,
    required this.taxCode,
    required this.taxType,
    required this.taxPercentage,
    this.description,
    required this.status,
  });

  factory TaxAggregateDto.fromJson(Map<String, dynamic> json) {
    return TaxAggregateDto(
      id: json['id']?.toString() ?? '',
      taxName: json['taxName']?.toString() ?? '',
      taxCode: json['taxCode']?.toString() ?? '',
      taxType: json['taxType']?.toString() ?? 'PERCENTAGE',
      taxPercentage: (json['taxPercentage'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  final String id;
  final String taxName;
  final String taxCode;
  final String taxType;
  final double taxPercentage;
  final String? description;
  final String status;
}

class TaxAggregateListResultDto {
  const TaxAggregateListResultDto({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  factory TaxAggregateListResultDto.fromJson(Map<String, dynamic> json) {
    return TaxAggregateListResultDto(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => TaxAggregateDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 100,
      totalCount: json['totalCount'] as int? ?? 0,
    );
  }

  final List<TaxAggregateDto> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
}

class TaxAggregateCreateRequestDto {
  const TaxAggregateCreateRequestDto({
    required this.taxName,
    required this.taxCode,
    required this.taxType,
    required this.taxPercentage,
    this.description,
    required this.status,
  });

  final String taxName;
  final String taxCode;
  final String taxType;
  final double taxPercentage;
  final String? description;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      'taxName': taxName,
      'taxCode': taxCode,
      'taxType': taxType,
      'taxPercentage': taxPercentage,
      if (description != null) 'description': description,
      'status': status,
    };
  }
}

class TaxAggregateUpdateRequestDto {
  const TaxAggregateUpdateRequestDto({
    required this.taxName,
    required this.taxType,
    required this.taxPercentage,
    this.description,
    required this.status,
  });

  final String taxName;
  final String taxType;
  final double taxPercentage;
  final String? description;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      'taxName': taxName,
      'taxType': taxType,
      'taxPercentage': taxPercentage,
      if (description != null) 'description': description,
      'status': status,
    };
  }
}
