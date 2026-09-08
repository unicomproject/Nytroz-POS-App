import 'tax_status.dart';
import 'tax_treatment.dart';

class TaxSetup {
  const TaxSetup({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.taxTreatment,
    required this.status,
    this.currentRate,
    this.currentRateEffectiveFrom,
    this.nextRate,
    this.nextRateEffectiveFrom,
    this.productCount = 0,
    this.isSeeded,
    this.rateHistory,
  });

  final String id;
  final String name;
  final String code;
  final String? description;
  final TaxTreatment taxTreatment;
  final TaxStatus status;
  final double? currentRate;
  final DateTime? currentRateEffectiveFrom;
  final double? nextRate;
  final DateTime? nextRateEffectiveFrom;
  final int productCount;
  final bool? isSeeded;
  final List<TaxRateHistoryItem>? rateHistory;

  /// Legacy aliases used by Product Step 6 until create-options lands.
  String get taxName => name;
  double get taxPercentage => currentRate ?? 0;
}

class TaxRateHistoryItem {
  const TaxRateHistoryItem({
    required this.id,
    required this.rate,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.state,
    this.notes,
  });

  final String id;
  final double rate;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final TaxRateHistoryState state;
  final String? notes;
}

class TaxProductUsing {
  const TaxProductUsing({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.status,
    required this.taxPriceMode,
  });

  final String productId;
  final String productName;
  final String productCode;
  final String status;
  final TaxPriceMode taxPriceMode;
}

class TaxSetupListResult {
  const TaxSetupListResult({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  final List<TaxSetup> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
}

class TaxProductUsingListResult {
  const TaxProductUsingListResult({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  final List<TaxProductUsing> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
}

class TaxSetupCreateInput {
  const TaxSetupCreateInput({
    required this.name,
    required this.code,
    this.description,
    required this.taxTreatment,
    this.initialRate,
    required this.effectiveFrom,
  });

  final String name;
  final String code;
  final String? description;
  final TaxTreatment taxTreatment;
  final double? initialRate;
  final DateTime effectiveFrom;
}

class TaxSetupUpdateInput {
  const TaxSetupUpdateInput({
    required this.name,
    this.code,
    this.description,
    this.taxTreatment,
  });

  final String name;
  final String? code;
  final String? description;
  final TaxTreatment? taxTreatment;
}

class TaxRateScheduleInput {
  const TaxRateScheduleInput({
    required this.newRate,
    required this.effectiveFrom,
    this.notes,
  });

  final double newRate;
  final DateTime effectiveFrom;
  final String? notes;
}

class TaxStatusChangeResult {
  const TaxStatusChangeResult({
    required this.id,
    required this.status,
    required this.productCount,
  });

  final String id;
  final TaxStatus status;
  final int productCount;
}

class TaxSetupListQuery {
  const TaxSetupListQuery({
    this.search = '',
    this.status,
    this.pageNumber = 1,
    this.pageSize = 5,
  });

  final String search;
  final TaxStatus? status;
  final int pageNumber;
  final int pageSize;
}

class TaxProductsQuery {
  const TaxProductsQuery({
    this.search = '',
    this.pageNumber = 1,
    this.pageSize = 5,
  });

  final String search;
  final int pageNumber;
  final int pageSize;
}
