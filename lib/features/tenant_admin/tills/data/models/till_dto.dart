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
    this.lastActiveAt,
  });

  factory TillDto.fromJson(Map<String, dynamic> json) {
    final deviceStatus = (json['deviceStatus'] as String? ?? '').toLowerCase();
    final needsAttention = json['needsAttention'] == true;

    return TillDto(
      id: json['tillId']?.toString() ?? json['id']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      outletName: json['outletName'] as String? ?? '',
      name: json['tillName'] as String? ?? json['name'] as String? ?? '',
      code: json['tillCode'] as String? ?? json['code'] as String? ?? '',
      status: json['status'] as String? ?? '',
      operationalStatus: _operationalStatus(deviceStatus, needsAttention),
      attentionLabel: needsAttention ? 'Needs attention' : null,
      lastActiveAt: _dateValue(json['lastActiveAt'] ?? json['lastSyncAt']),
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
  final DateTime? lastActiveAt;

  static String _operationalStatus(String deviceStatus, bool needsAttention) {
    if (needsAttention) {
      return 'needs_attention';
    }

    switch (deviceStatus) {
      case 'online':
        return 'online';
      case 'offline':
        return 'offline';
      default:
        return deviceStatus;
    }
  }
}

class TillListSummaryDto {
  const TillListSummaryDto({
    required this.totalTills,
    required this.onlineCount,
    required this.offlineCount,
    required this.inactiveCount,
    required this.needsAttentionCount,
  });

  factory TillListSummaryDto.fromJson(Map<String, dynamic> json) {
    return TillListSummaryDto(
      totalTills: _intValue(json['totalTills']),
      onlineCount: _intValue(json['onlineTills'] ?? json['onlineCount']),
      offlineCount: _intValue(json['offlineTills'] ?? json['offlineCount']),
      inactiveCount: _intValue(json['inactiveTills'] ?? json['inactiveCount']),
      needsAttentionCount: _intValue(
        json['needsAttentionTills'] ?? json['needsAttentionCount'],
      ),
    );
  }

  final int totalTills;
  final int onlineCount;
  final int offlineCount;
  final int inactiveCount;
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

  factory TillListResultDto.fromJson(
    Map<String, dynamic> json, {
    TillListSummaryDto? summary,
  }) {
    final rawItems = json['items'];
    final items = _mapList(rawItems, TillDto.fromJson);
    final page = _intValue(json['page'], fallback: 1);
    final pageSize = _intValue(json['pageSize'], fallback: 10);
    final totalCount = _intValue(json['totalCount'], fallback: items.length);

    return TillListResultDto(
      summary: summary ??
          (json['summary'] is Map
              ? TillListSummaryDto.fromJson(
                  Map<String, dynamic>.from(json['summary'] as Map),
                )
              : TillListSummaryDto(
                  totalTills: totalCount,
                  onlineCount: 0,
                  offlineCount: 0,
                  inactiveCount: 0,
                  needsAttentionCount: 0,
                )),
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
      id: json['tillId']?.toString() ?? json['id']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      name: json['tillName'] as String? ?? json['name'] as String? ?? '',
      code: json['tillCode'] as String? ?? json['code'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String id;
  final String outletId;
  final String name;
  final String code;
  final String status;
}

class OutletOptionDto {
  const OutletOptionDto({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
  });

  factory OutletOptionDto.fromJson(Map<String, dynamic> json) {
    return OutletOptionDto(
      id: json['outletId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['outletName'] as String? ?? json['name'] as String? ?? '',
      code: json['outletCode'] as String? ?? json['code'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String id;
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
