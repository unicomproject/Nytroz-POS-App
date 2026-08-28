class TaxAggregate {
  const TaxAggregate({
    required this.id,
    required this.taxName,
    required this.taxCode,
    required this.taxType,
    required this.taxPercentage,
    this.description,
    required this.status,
  });

  final String id;
  final String taxName;
  final String taxCode;
  final String taxType;
  final double taxPercentage;
  final String? description;
  final String status;
}

class TaxAggregateListResult {
  const TaxAggregateListResult({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  final List<TaxAggregate> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
}

class TaxAggregateUpsertInput {
  const TaxAggregateUpsertInput({
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
}
