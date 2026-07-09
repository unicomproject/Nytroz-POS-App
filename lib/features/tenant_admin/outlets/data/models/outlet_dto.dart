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
    this.outletType,
    this.contactNumber,
    this.city,
  });

  factory OutletDto.fromJson(Map<String, dynamic> json) {
    return OutletDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? json['outletName'] as String? ?? '',
      code: json['code'] as String? ?? json['outletCode'] as String? ?? '',
      location: json['location'] as String? ?? json['address'] as String? ?? '',
      status: json['status'] as String? ?? '',
      tillCount: _intValue(json['tillCount'] ?? json['tills']),
      onlineTillCount:
          _intValue(json['onlineTillCount'] ?? json['onlineTills']),
      staffCount: _intValue(json['staffCount'] ?? json['staff']),
      todaysSales: _formatSales(json['todaysSales'] ?? json['todaySales']),
      outletType: json['outletType'] as String? ?? json['type'] as String?,
      contactNumber:
          json['phone'] as String? ?? json['contactNumber'] as String?,
      city: json['city'] as String?,
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
  final String? outletType;
  final String? contactNumber;
  final String? city;
}

class OutletListResultDto {
  const OutletListResultDto({
    required this.summary,
    required this.items,
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
  });

  factory OutletListResultDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['outlets'];
    final items = _mapList(rawItems, OutletDto.fromJson);
    final page = _intValue(json['page'] ?? json['pageNumber'], fallback: 1);
    final pageSize = _intValue(json['pageSize'], fallback: 10);
    final totalCount = _intValue(json['totalCount'], fallback: items.length);

    return OutletListResultDto(
      summary: json['summary'] is Map
          ? OutletListSummaryDto.fromJson(
              Map<String, dynamic>.from(json['summary'] as Map),
            )
          : OutletListSummaryDto.fromPagedList(
              items: items,
              totalCount: totalCount,
            ),
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }

  factory OutletListResultDto.fromArray(List<dynamic> items) {
    final outlets = _mapList(items, OutletDto.fromJson);

    return OutletListResultDto(
      summary: OutletListSummaryDto.fromPagedList(
        items: outlets,
        totalCount: outlets.length,
      ),
      items: outlets,
      page: 1,
      pageSize: outlets.length,
      totalCount: outlets.length,
    );
  }

  final OutletListSummaryDto summary;
  final List<OutletDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
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

  factory OutletListSummaryDto.fromPagedList({
    required List<OutletDto> items,
    required int totalCount,
  }) {
    final active =
        items.where((outlet) => outlet.status.toLowerCase() == 'active').length;

    return OutletListSummaryDto(
      totalOutlets: totalCount,
      activeOutlets: active,
      inactiveOutlets: items.length - active,
      totalLocations: totalCount,
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
    this.phone,
    this.email,
    this.managerName,
    this.managerPhone,
    this.openingHours,
    this.todaysStatus,
    this.tillCount,
    this.onlineTillCount,
    this.staffCount,
    this.todaySalesAmount,
    this.todaySalesCurrency,
    this.weekSalesAmount,
    this.weekSalesCurrency,
    this.metrics = const [],
    this.assignedTills = const [],
    this.staff = const [],
    this.needsAttention = const [],
    this.timezone,
  });

  factory OutletDetailsDto.fromJson(Map<String, dynamic> json) {
    final todaySales = json['todaySales'] ?? json['todaysSales'];
    final weekSales = json['weekSales'];

    return OutletDetailsDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? json['outletName'] as String? ?? '',
      code: json['code'] as String? ?? json['outletCode'] as String? ?? '',
      address: json['address'] is String
          ? json['address'] as String
          : _formatAddress(
              json['address'] is Map
                  ? Map<String, dynamic>.from(json['address'] as Map)
                  : json,
            ),
      status: json['status'] as String? ?? '',
      timezone: json['timezone'] as String?,
      phone: json['phone'] as String? ?? json['contactPhone'] as String?,
      email: json['email'] as String? ?? json['contactEmail'] as String?,
      managerName: json['managerName'] as String?,
      managerPhone: json['managerPhone'] as String? ?? json['phone'] as String?,
      openingHours: json['openingHours']?.toString(),
      todaysStatus: json['todaysStatus'] as String?,
      tillCount: _nullableInt(json['tillCount']),
      onlineTillCount: _nullableInt(json['onlineTillCount']),
      staffCount: _nullableInt(json['staffCount']),
      todaySalesAmount: _salesAmount(todaySales),
      todaySalesCurrency: _salesCurrency(todaySales),
      weekSalesAmount: _salesAmount(weekSales),
      weekSalesCurrency: _salesCurrency(weekSales),
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
  final String? timezone;
  final String? phone;
  final String? email;
  final String? managerName;
  final String? managerPhone;
  final String? openingHours;
  final String? todaysStatus;
  final int? tillCount;
  final int? onlineTillCount;
  final int? staffCount;
  final double? todaySalesAmount;
  final String? todaySalesCurrency;
  final double? weekSalesAmount;
  final String? weekSalesCurrency;
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
    this.route,
  });

  factory OutletAttentionItemDto.fromJson(Map<String, dynamic> json) {
    return OutletAttentionItemDto(
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String?,
      route: json['route'] as String?,
    );
  }

  final String title;
  final String message;
  final String? status;
  final String? route;
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

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _formatSales(Object? value) {
  if (value is Map) {
    final amount = value['amount'];
    final currency = value['currency']?.toString() ?? '';
    if (amount == null) {
      return '';
    }

    final formattedAmount = amount is num
        ? amount.toStringAsFixed(amount is int ? 0 : 2)
        : amount.toString();

    return currency.isEmpty ? formattedAmount : '$currency $formattedAmount';
  }

  return value?.toString() ?? '';
}

int? _nullableInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  return int.tryParse(value.toString());
}

double? _salesAmount(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is Map) {
    final amount = value['amount'];
    if (amount is num) {
      return amount.toDouble();
    }
  }

  return double.tryParse(value?.toString() ?? '');
}

String? _salesCurrency(Object? value) {
  if (value is Map) {
    return value['currency']?.toString();
  }

  return null;
}

String _formatAddress(Map<String, dynamic> json) {
  final parts = [
    json['addressLine1'],
    json['addressLine2'],
    json['city'],
    json['postalCode'],
    json['countryCode'] ?? json['country'],
  ]
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty);

  return parts.join(', ');
}
