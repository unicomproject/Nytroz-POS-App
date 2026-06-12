class OutletDto {
  const OutletDto({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.status,
    required this.tillCount,
    required this.onlineTillCount,
    required this.staffCount,
    required this.todaysSales,
  });

  factory OutletDto.fromJson(Map<String, dynamic> json) {
    return OutletDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['outletName'] as String? ?? '',
      code: json['code'] as String? ?? json['outletCode'] as String? ?? '',
      location: json['location'] as String? ?? json['address'] as String? ?? '',
      status: json['status'] as String? ?? '',
      tillCount: _intValue(json['tillCount'] ?? json['tills']),
      onlineTillCount:
          _intValue(json['onlineTillCount'] ?? json['onlineTills']),
      staffCount: _intValue(json['staffCount'] ?? json['staff']),
      todaysSales: json['todaysSales']?.toString() ??
          json['todaySales']?.toString() ??
          '',
    );
  }

  final String id;
  final String name;
  final String code;
  final String location;
  final String status;
  final int tillCount;
  final int onlineTillCount;
  final int staffCount;
  final String todaysSales;
}

class OutletListResultDto {
  const OutletListResultDto({
    required this.summary,
    required this.items,
  });

  factory OutletListResultDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['outlets'];

    return OutletListResultDto(
      summary: OutletListSummaryDto.fromJson(
        Map<String, dynamic>.from(json['summary'] as Map? ?? const {}),
      ),
      items: _mapList(rawItems, OutletDto.fromJson),
    );
  }

  factory OutletListResultDto.fromArray(List<dynamic> items) {
    final outlets = _mapList(items, OutletDto.fromJson);
    final active = outlets
        .where((outlet) => outlet.status.toLowerCase() == 'active')
        .length;

    return OutletListResultDto(
      summary: OutletListSummaryDto(
        totalOutlets: outlets.length,
        activeOutlets: active,
        inactiveOutlets: outlets.length - active,
        totalLocations: outlets.length,
      ),
      items: outlets,
    );
  }

  final OutletListSummaryDto summary;
  final List<OutletDto> items;
}

class OutletListSummaryDto {
  const OutletListSummaryDto({
    required this.totalOutlets,
    required this.activeOutlets,
    required this.inactiveOutlets,
    required this.totalLocations,
  });

  factory OutletListSummaryDto.fromJson(Map<String, dynamic> json) {
    return OutletListSummaryDto(
      totalOutlets: _intValue(json['totalOutlets']),
      activeOutlets: _intValue(json['activeOutlets']),
      inactiveOutlets: _intValue(json['inactiveOutlets']),
      totalLocations: _intValue(json['totalLocations']),
    );
  }

  final int totalOutlets;
  final int activeOutlets;
  final int inactiveOutlets;
  final int totalLocations;
}

class OutletDetailsDto {
  const OutletDetailsDto({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.status,
    this.managerName,
    this.managerPhone,
    this.openingHours,
    this.todaysStatus,
    required this.metrics,
    required this.assignedTills,
    required this.staff,
    required this.needsAttention,
  });

  factory OutletDetailsDto.fromJson(Map<String, dynamic> json) {
    return OutletDetailsDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['outletName'] as String? ?? '',
      code: json['code'] as String? ?? json['outletCode'] as String? ?? '',
      address: json['address'] as String? ?? '',
      status: json['status'] as String? ?? '',
      managerName: json['managerName'] as String?,
      managerPhone: json['managerPhone'] as String?,
      openingHours: json['openingHours']?.toString(),
      todaysStatus: json['todaysStatus'] as String?,
      metrics: _mapList(json['metrics'], OutletDetailMetricDto.fromJson),
      assignedTills:
          _mapList(json['assignedTills'], OutletRelatedItemDto.fromJson),
      staff: _mapList(json['staff'], OutletRelatedItemDto.fromJson),
      needsAttention:
          _mapList(json['needsAttention'], OutletAttentionItemDto.fromJson),
    );
  }

  final String id;
  final String name;
  final String code;
  final String address;
  final String status;
  final String? managerName;
  final String? managerPhone;
  final String? openingHours;
  final String? todaysStatus;
  final List<OutletDetailMetricDto> metrics;
  final List<OutletRelatedItemDto> assignedTills;
  final List<OutletRelatedItemDto> staff;
  final List<OutletAttentionItemDto> needsAttention;
}

class OutletDetailMetricDto {
  const OutletDetailMetricDto({
    required this.title,
    required this.value,
    this.subtitle,
    this.iconKey,
  });

  factory OutletDetailMetricDto.fromJson(Map<String, dynamic> json) {
    return OutletDetailMetricDto(
      title: json['title'] as String? ?? '',
      value: json['value']?.toString() ?? '',
      subtitle: json['subtitle'] as String?,
      iconKey: json['iconKey'] as String?,
    );
  }

  final String title;
  final String value;
  final String? subtitle;
  final String? iconKey;
}

class OutletRelatedItemDto {
  const OutletRelatedItemDto({
    required this.id,
    required this.title,
    this.subtitle,
    this.status,
  });

  factory OutletRelatedItemDto.fromJson(Map<String, dynamic> json) {
    return OutletRelatedItemDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      status: json['status'] as String?,
    );
  }

  final String id;
  final String title;
  final String? subtitle;
  final String? status;
}

class OutletAttentionItemDto {
  const OutletAttentionItemDto({
    required this.title,
    required this.message,
    this.status,
  });

  factory OutletAttentionItemDto.fromJson(Map<String, dynamic> json) {
    return OutletAttentionItemDto(
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String?,
    );
  }

  final String title;
  final String message;
  final String? status;
}

class OutletManagerOptionDto {
  const OutletManagerOptionDto({
    required this.id,
    required this.displayName,
  });

  factory OutletManagerOptionDto.fromJson(Map<String, dynamic> json) {
    return OutletManagerOptionDto(
      id: json['id'] as String? ?? '',
      displayName:
          json['displayName'] as String? ?? json['name'] as String? ?? '',
    );
  }

  final String id;
  final String displayName;
}

List<T> _mapList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
