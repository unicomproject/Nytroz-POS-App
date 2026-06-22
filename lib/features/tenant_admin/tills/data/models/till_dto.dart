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
    final normalized = _normalizeJsonKeys(json);
    return TillDto(
      id: normalized['id']?.toString() ?? '',
      outletId: normalized['outletId']?.toString() ?? '',
      outletName: normalized['outletName'] as String? ?? '',
      name: normalized['name'] as String? ?? '',
      code: normalized['code'] as String? ?? '',
      status: normalized['status'] as String? ?? '',
      operationalStatus: normalized['operationalStatus'] as String? ?? '',
      attentionLabel: normalized['attentionLabel'] as String?,
      todaySalesAmount: _doubleValue(normalized['todaySalesAmount']),
      currency: normalized['currency'] as String?,
      lastSyncAt: _dateValue(normalized['lastSyncAt']),
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

class TillListResultDto {
  const TillListResultDto({
    required this.summary,
    required this.items,
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
  });

  factory TillListResultDto.fromJson(Map<String, dynamic> json) {
    final normalized = _normalizeJsonKeys(json);
    final rawItems = normalized['items'] ?? normalized['tills'];
    final items = _mapList(rawItems, TillDto.fromJson);
    final page = _intValue(normalized['page'], fallback: 1);
    final pageSize = _intValue(normalized['pageSize'], fallback: 10);
    final totalCount = _intValue(normalized['totalCount'], fallback: items.length);

    return TillListResultDto(
      summary: normalized['summary'] is Map
          ? TillListSummaryDto.fromJson(
              _normalizeJsonKeys(
                Map<String, dynamic>.from(normalized['summary'] as Map),
              ),
            )
          : TillListSummaryDto.fromItems(items),
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

class TillListSummaryDto {
  const TillListSummaryDto({
    required this.totalTills,
    required this.onlineCount,
    required this.offlineCount,
    required this.needsAttentionCount,
  });

  factory TillListSummaryDto.fromJson(Map<String, dynamic> json) {
    final normalized = _normalizeJsonKeys(json);
    return TillListSummaryDto(
      totalTills: _intValue(normalized['totalTills']),
      onlineCount: _intValue(normalized['onlineCount']),
      offlineCount: _intValue(normalized['offlineCount']),
      needsAttentionCount: _intValue(normalized['needsAttentionCount']),
    );
  }

  factory TillListSummaryDto.fromItems(List<TillDto> items) {
    return TillListSummaryDto(
      totalTills: items.length,
      onlineCount: items
          .where((item) => item.operationalStatus.toLowerCase() == 'online')
          .length,
      offlineCount: items
          .where((item) => item.operationalStatus.toLowerCase() == 'offline')
          .length,
      needsAttentionCount: items.where((item) {
        final status = item.operationalStatus.toLowerCase();
        return status == 'needs_attention' || status == 'offline';
      }).length,
    );
  }

  final int totalTills;
  final int onlineCount;
  final int offlineCount;
  final int needsAttentionCount;
}

List<T> _mapList<T>(
  dynamic rawItems,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (rawItems is! List) {
    return const [];
  }

  return rawItems
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList(growable: false);
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
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '');
}

DateTime? _dateValue(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}

Map<String, dynamic> _normalizeJsonKeys(Map<String, dynamic> json) {
  return json.map(
    (key, value) => MapEntry(
      key.isEmpty ? key : key[0].toLowerCase() + key.substring(1),
      value,
    ),
  );
}
