import '../domain/tax_aggregate.dart';
import '../domain/tax_status.dart';
import '../domain/tax_treatment.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _parseInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _pickString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) {
      return json[key];
    }
  }
  return null;
}

class TaxSetupDto {
  const TaxSetupDto({
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
    this.rateHistory = const [],
  });

  factory TaxSetupDto.fromJson(Map<String, dynamic> json) {
    final historyRaw = json['rateHistory'];
    return TaxSetupDto(
      id: json['id']?.toString() ?? '',
      name: _pickString(json, ['name', 'taxName']),
      code: _pickString(json, ['code', 'taxCode']),
      description: json['description']?.toString(),
      taxTreatment: TaxTreatment.parse(
        _pick(json, ['taxTreatment', 'taxType'])?.toString(),
      ),
      status: TaxStatus.parse(json['status']?.toString()),
      currentRate: _parseDouble(
        _pick(json, ['currentRate', 'taxPercentage']),
      ),
      currentRateEffectiveFrom: _parseDate(json['currentRateEffectiveFrom']),
      nextRate: _parseDouble(json['nextRate']),
      nextRateEffectiveFrom: _parseDate(json['nextRateEffectiveFrom']),
      productCount: _parseInt(json['productCount']),
      isSeeded: json['isSeeded'] is bool ? json['isSeeded'] as bool : null,
      rateHistory: historyRaw is List
          ? historyRaw
              .whereType<Map>()
              .map(
                (e) => TaxRateHistoryItemDto.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }

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
  final List<TaxRateHistoryItemDto> rateHistory;

  TaxSetup toDomain() {
    return TaxSetup(
      id: id,
      name: name,
      code: code,
      description: description,
      taxTreatment: taxTreatment,
      status: status,
      currentRate: currentRate,
      currentRateEffectiveFrom: currentRateEffectiveFrom,
      nextRate: nextRate,
      nextRateEffectiveFrom: nextRateEffectiveFrom,
      productCount: productCount,
      isSeeded: isSeeded,
      rateHistory: rateHistory.map((e) => e.toDomain()).toList(),
    );
  }
}

class TaxRateHistoryItemDto {
  const TaxRateHistoryItemDto({
    required this.id,
    required this.rate,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.state,
    this.notes,
  });

  factory TaxRateHistoryItemDto.fromJson(Map<String, dynamic> json) {
    return TaxRateHistoryItemDto(
      id: json['id']?.toString() ?? '',
      rate: _parseDouble(json['rate']) ?? 0,
      effectiveFrom: _parseDate(json['effectiveFrom']) ?? DateTime.now(),
      effectiveTo: _parseDate(json['effectiveTo']),
      state: TaxRateHistoryState.parse(json['state']?.toString()),
      notes: json['notes']?.toString(),
    );
  }

  final String id;
  final double rate;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final TaxRateHistoryState state;
  final String? notes;

  TaxRateHistoryItem toDomain() {
    return TaxRateHistoryItem(
      id: id,
      rate: rate,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      state: state,
      notes: notes,
    );
  }
}

class TaxSetupListResultDto {
  const TaxSetupListResultDto({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  factory TaxSetupListResultDto.fromJson(Map<String, dynamic> json) {
    return TaxSetupListResultDto(
      items: (json['items'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (e) => TaxSetupDto.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          const [],
      pageNumber: _parseInt(json['pageNumber'], 1),
      pageSize: _parseInt(json['pageSize'], 5),
      totalCount: _parseInt(json['totalCount']),
    );
  }

  final List<TaxSetupDto> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;

  TaxSetupListResult toDomain() {
    return TaxSetupListResult(
      items: items.map((e) => e.toDomain()).toList(),
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }
}

class TaxProductUsingDto {
  const TaxProductUsingDto({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.status,
    required this.taxPriceMode,
  });

  factory TaxProductUsingDto.fromJson(Map<String, dynamic> json) {
    return TaxProductUsingDto(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      taxPriceMode: TaxPriceMode.parse(json['taxPriceMode']?.toString()),
    );
  }

  final String productId;
  final String productName;
  final String productCode;
  final String status;
  final TaxPriceMode taxPriceMode;

  TaxProductUsing toDomain() {
    return TaxProductUsing(
      productId: productId,
      productName: productName,
      productCode: productCode,
      status: status,
      taxPriceMode: taxPriceMode,
    );
  }
}

class TaxProductUsingListResultDto {
  const TaxProductUsingListResultDto({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  factory TaxProductUsingListResultDto.fromJson(Map<String, dynamic> json) {
    return TaxProductUsingListResultDto(
      items: (json['items'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (e) =>
                    TaxProductUsingDto.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          const [],
      pageNumber: _parseInt(json['pageNumber'], 1),
      pageSize: _parseInt(json['pageSize'], 5),
      totalCount: _parseInt(json['totalCount']),
    );
  }

  final List<TaxProductUsingDto> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;

  TaxProductUsingListResult toDomain() {
    return TaxProductUsingListResult(
      items: items.map((e) => e.toDomain()).toList(),
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }
}

class TaxSetupCreateRequestDto {
  const TaxSetupCreateRequestDto({
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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      if (description != null && description!.trim().isNotEmpty)
        'description': description,
      'taxTreatment': taxTreatment.apiValue,
      if (initialRate != null) 'initialRate': initialRate,
      'effectiveFrom': _formatDateOnly(effectiveFrom),
    };
  }
}

class TaxSetupUpdateRequestDto {
  const TaxSetupUpdateRequestDto({
    required this.name,
    this.code,
    this.description,
    this.taxTreatment,
  });

  final String name;
  final String? code;
  final String? description;
  final TaxTreatment? taxTreatment;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (taxTreatment != null) 'taxTreatment': taxTreatment!.apiValue,
    };
  }
}

class TaxRateScheduleRequestDto {
  const TaxRateScheduleRequestDto({
    required this.newRate,
    required this.effectiveFrom,
    this.notes,
  });

  final double newRate;
  final DateTime effectiveFrom;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'newRate': newRate,
      'effectiveFrom': _formatDateOnly(effectiveFrom),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
    };
  }
}

class TaxStatusChangeResultDto {
  const TaxStatusChangeResultDto({
    required this.id,
    required this.status,
    required this.productCount,
  });

  factory TaxStatusChangeResultDto.fromJson(Map<String, dynamic> json) {
    return TaxStatusChangeResultDto(
      id: json['id']?.toString() ?? '',
      status: TaxStatus.parse(json['status']?.toString()),
      productCount: _parseInt(json['productCount']),
    );
  }

  final String id;
  final TaxStatus status;
  final int productCount;

  TaxStatusChangeResult toDomain() {
    return TaxStatusChangeResult(
      id: id,
      status: status,
      productCount: productCount,
    );
  }
}

String _formatDateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
