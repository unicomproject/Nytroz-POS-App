class TillDto {
  const TillDto({
    required this.id,
    required this.outletId,
    required this.outletName,
    required this.name,
    required this.code,
    required this.status,
    required this.operationalStatus,
    this.attentionLabel,
    this.todaySalesAmount,
    this.currency,
    this.lastSyncAt,
  });

  factory TillDto.fromJson(Map<String, dynamic> json) {
    return TillDto(
      id: json['id']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      outletName: json['outletName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: json['status'] as String? ?? '',
      operationalStatus: json['operationalStatus'] as String? ?? '',
      attentionLabel: json['attentionLabel'] as String?,
      todaySalesAmount: _doubleValue(json['todaySalesAmount']),
      currency: json['currency'] as String?,
      lastSyncAt: _dateValue(json['lastSyncAt']),
    );
  }

  final String id;
  final String outletId;
  final String outletName;
  final String name;
  final String code;
  final String status;
  final String operationalStatus;
  final String? attentionLabel;
  final double? todaySalesAmount;
  final String? currency;
  final DateTime? lastSyncAt;
}

class TillListSummaryDto {
  const TillListSummaryDto({
    required this.totalTills,
    required this.onlineCount,
    required this.offlineCount,
    required this.needsAttentionCount,
  });

  factory TillListSummaryDto.fromJson(Map<String, dynamic> json) {
    return TillListSummaryDto(
      totalTills: _intValue(json['totalTills']),
      onlineCount: _intValue(json['onlineCount']),
      offlineCount: _intValue(json['offlineCount']),
      needsAttentionCount: _intValue(json['needsAttentionCount']),
    );
  }

  factory TillListSummaryDto.fromPagedList({
    required List<TillDto> items,
    required int totalCount,
  }) {
    var online = 0;
    var offline = 0;
    var needsAttention = 0;

    for (final item in items) {
      switch (item.operationalStatus) {
        case 'online':
          online++;
        case 'offline':
          offline++;
        case 'needs_attention':
          needsAttention++;
      }
    }

    return TillListSummaryDto(
      totalTills: totalCount,
      onlineCount: online,
      offlineCount: offline,
      needsAttentionCount: needsAttention,
    );
  }

  final int totalTills;
  final int onlineCount;
  final int offlineCount;
  final int needsAttentionCount;
}

class TillListResultDto {
  const TillListResultDto({
    required this.summary,
    required this.items,
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
  });

  factory TillListResultDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = _mapList(rawItems, TillDto.fromJson);
    final page = _intValue(json['page'], fallback: 1);
    final pageSize = _intValue(json['pageSize'], fallback: 10);
    final totalCount = _intValue(json['totalCount'], fallback: items.length);

    return TillListResultDto(
      summary: json['summary'] is Map
          ? TillListSummaryDto.fromJson(
              Map<String, dynamic>.from(json['summary'] as Map),
            )
          : TillListSummaryDto.fromPagedList(
              items: items,
              totalCount: totalCount,
            ),
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }

  final TillListSummaryDto summary;
  final List<TillDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
}

class CreatedTillDto {
  const CreatedTillDto({
    required this.id,
    required this.outletId,
    required this.name,
    required this.code,
    required this.status,
  });

  factory CreatedTillDto.fromJson(Map<String, dynamic> json) {
    return CreatedTillDto(
      id: json['id']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String id;
  final String outletId;
  final String name;
  final String code;
  final String status;
}

int _intValue(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _doubleValue(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

DateTime? _dateValue(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}

List<T> _mapList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (raw is! List) {
    return const [];
  }

  return raw
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}
