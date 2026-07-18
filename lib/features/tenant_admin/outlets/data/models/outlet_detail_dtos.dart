class OutletDetailDto {
  const OutletDetailDto({
    required this.outletId,
    required this.outletName,
    required this.outletCode,
    required this.outletType,
    required this.status,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.districtOrProvince,
    this.postalCode,
    this.phoneNumber,
    this.emailAddress,
    this.managerName,
    this.operatingHours,
    this.openingDate,
    this.taxRegistrationId,
    this.notes,
  });

  factory OutletDetailDto.fromJson(Map<String, dynamic> json) {
    final address = json['address'] is Map
        ? Map<String, dynamic>.from(json['address'] as Map)
        : const <String, dynamic>{};

    return OutletDetailDto(
      outletId: json['outletId']?.toString() ?? json['id']?.toString() ?? '',
      outletName: json['outletName'] as String? ?? json['name'] as String? ?? '',
      outletCode: json['outletCode'] as String? ?? json['code'] as String? ?? '',
      outletType: json['outletType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      addressLine1:
          address['addressLine1'] as String? ?? json['addressLine1'] as String?,
      addressLine2:
          address['addressLine2'] as String? ?? json['addressLine2'] as String?,
      city: address['city'] as String? ?? json['city'] as String?,
      districtOrProvince: address['stateOrProvince'] as String? ??
          address['state'] as String? ??
          json['districtOrProvince'] as String?,
      postalCode:
          address['postalCode'] as String? ?? json['postalCode'] as String?,
      phoneNumber: json['phoneNumber'] as String? ??
          json['phone'] as String? ??
          json['contactPhone'] as String?,
      emailAddress: json['emailAddress'] as String? ??
          json['email'] as String? ??
          json['contactEmail'] as String?,
      managerName: json['managerName'] as String?,
      operatingHours: json['operatingHours'] as String?,
      openingDate: json['openingDate']?.toString(),
      taxRegistrationId: json['taxRegistrationId'] as String?,
      notes: json['notes'] as String?,
    );
  }

  final String outletId;
  final String outletName;
  final String outletCode;
  final String outletType;
  final String status;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? districtOrProvince;
  final String? postalCode;
  final String? phoneNumber;
  final String? emailAddress;
  final String? managerName;
  final String? operatingHours;
  final String? openingDate;
  final String? taxRegistrationId;
  final String? notes;
}

class OutletRevenueSummaryDto {
  const OutletRevenueSummaryDto({
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.totalOrders,
    required this.refunds,
    this.revenueChangePercent,
    this.averageOrderValueChangePercent,
    this.ordersChangePercent,
    this.refundsChangePercent,
    required this.revenueOverTime,
    required this.revenueByPaymentMethod,
    required this.revenueSummary,
  });

  factory OutletRevenueSummaryDto.fromJson(Map<String, dynamic> json) {
    return OutletRevenueSummaryDto(
      totalRevenue: _decimal(json['totalRevenue']),
      averageOrderValue: _decimal(json['averageOrderValue']),
      totalOrders: _int(json['totalOrders']),
      refunds: _decimal(json['refunds']),
      revenueChangePercent: _nullableDecimal(json['revenueChangePercent']),
      averageOrderValueChangePercent:
          _nullableDecimal(json['averageOrderValueChangePercent']),
      ordersChangePercent: _nullableDecimal(json['ordersChangePercent']),
      refundsChangePercent: _nullableDecimal(json['refundsChangePercent']),
      revenueOverTime: _mapList(
        json['revenueOverTime'],
        OutletRevenuePointDto.fromJson,
      ),
      revenueByPaymentMethod: _mapList(
        json['revenueByPaymentMethod'],
        OutletPaymentMethodShareDto.fromJson,
      ),
      revenueSummary: OutletRevenueBreakdownDto.fromJson(
        json['revenueSummary'] is Map
            ? Map<String, dynamic>.from(json['revenueSummary'] as Map)
            : const {},
      ),
    );
  }

  final double totalRevenue;
  final double averageOrderValue;
  final int totalOrders;
  final double refunds;
  final double? revenueChangePercent;
  final double? averageOrderValueChangePercent;
  final double? ordersChangePercent;
  final double? refundsChangePercent;
  final List<OutletRevenuePointDto> revenueOverTime;
  final List<OutletPaymentMethodShareDto> revenueByPaymentMethod;
  final OutletRevenueBreakdownDto revenueSummary;
}

class OutletRevenuePointDto {
  const OutletRevenuePointDto({required this.label, required this.amount});

  factory OutletRevenuePointDto.fromJson(Map<String, dynamic> json) {
    return OutletRevenuePointDto(
      label: json['label'] as String? ?? '',
      amount: _decimal(json['amount']),
    );
  }

  final String label;
  final double amount;
}

class OutletPaymentMethodShareDto {
  const OutletPaymentMethodShareDto({
    required this.method,
    required this.amount,
    required this.percent,
  });

  factory OutletPaymentMethodShareDto.fromJson(Map<String, dynamic> json) {
    return OutletPaymentMethodShareDto(
      method: json['method'] as String? ?? '',
      amount: _decimal(json['amount']),
      percent: _decimal(json['percent']),
    );
  }

  final String method;
  final double amount;
  final double percent;
}

class OutletRevenueBreakdownDto {
  const OutletRevenueBreakdownDto({
    required this.grossRevenue,
    required this.discounts,
    required this.returns,
    required this.netRevenue,
    required this.taxCollected,
  });

  factory OutletRevenueBreakdownDto.fromJson(Map<String, dynamic> json) {
    return OutletRevenueBreakdownDto(
      grossRevenue: _decimal(json['grossRevenue']),
      discounts: _decimal(json['discounts']),
      returns: _decimal(json['returns']),
      netRevenue: _decimal(json['netRevenue']),
      taxCollected: _decimal(json['taxCollected']),
    );
  }

  final double grossRevenue;
  final double discounts;
  final double returns;
  final double netRevenue;
  final double taxCollected;
}

class OutletAssignedUsersDto {
  const OutletAssignedUsersDto({
    required this.summary,
    required this.items,
  });

  factory OutletAssignedUsersDto.fromJson(Map<String, dynamic> json) {
    return OutletAssignedUsersDto(
      summary: OutletAssignedUsersSummaryDto.fromJson(
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : const {},
      ),
      items: _mapList(json['items'], OutletAssignedUserDto.fromJson),
    );
  }

  final OutletAssignedUsersSummaryDto summary;
  final List<OutletAssignedUserDto> items;
}

class OutletAssignedUsersSummaryDto {
  const OutletAssignedUsersSummaryDto({
    required this.totalAssignedUsers,
    required this.activeUsers,
    required this.pendingInvites,
    required this.managers,
  });

  factory OutletAssignedUsersSummaryDto.fromJson(Map<String, dynamic> json) {
    return OutletAssignedUsersSummaryDto(
      totalAssignedUsers: _int(json['totalAssignedUsers']),
      activeUsers: _int(json['activeUsers']),
      pendingInvites: _int(json['pendingInvites']),
      managers: _int(json['managers']),
    );
  }

  final int totalAssignedUsers;
  final int activeUsers;
  final int pendingInvites;
  final int managers;
}

class OutletAssignedUserDto {
  const OutletAssignedUserDto({
    required this.userId,
    required this.displayName,
    required this.roleName,
    this.assignedTillOrDepartment,
    this.phoneNumber,
    this.email,
    this.outletAccess,
    required this.status,
    this.lastActivity,
  });

  factory OutletAssignedUserDto.fromJson(Map<String, dynamic> json) {
    return OutletAssignedUserDto(
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName'] as String? ?? '',
      roleName: json['roleName'] as String? ?? '',
      assignedTillOrDepartment: json['assignedTillOrDepartment'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      outletAccess: json['outletAccess'] as String?,
      status: json['status'] as String? ?? '',
      lastActivity: json['lastActivity']?.toString(),
    );
  }

  final String userId;
  final String displayName;
  final String roleName;
  final String? assignedTillOrDepartment;
  final String? phoneNumber;
  final String? email;
  final String? outletAccess;
  final String status;
  final String? lastActivity;
}

class OutletTillsDetailDto {
  const OutletTillsDetailDto({
    required this.summary,
    required this.items,
  });

  factory OutletTillsDetailDto.fromJson(Map<String, dynamic> json) {
    return OutletTillsDetailDto(
      summary: OutletTillsSummaryDto.fromJson(
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : const {},
      ),
      items: _mapList(json['items'], OutletTillDetailItemDto.fromJson),
    );
  }

  final OutletTillsSummaryDto summary;
  final List<OutletTillDetailItemDto> items;
}

class OutletTillsSummaryDto {
  const OutletTillsSummaryDto({
    required this.totalTills,
    required this.activeTills,
    required this.currentlyOpenTills,
    required this.tillsNeedingAttention,
  });

  factory OutletTillsSummaryDto.fromJson(Map<String, dynamic> json) {
    return OutletTillsSummaryDto(
      totalTills: _int(json['totalTills']),
      activeTills: _int(json['activeTills']),
      currentlyOpenTills: _int(json['currentlyOpenTills']),
      tillsNeedingAttention: _int(json['tillsNeedingAttention']),
    );
  }

  final int totalTills;
  final int activeTills;
  final int currentlyOpenTills;
  final int tillsNeedingAttention;
}

class OutletTillDetailItemDto {
  const OutletTillDetailItemDto({
    required this.tillId,
    required this.tillName,
    required this.tillCode,
    required this.status,
    this.currentBalance,
    this.openingAmount,
    this.lastOpenedAt,
    this.lastClosedAt,
    this.assignedCashierName,
    required this.deviceStatus,
  });

  factory OutletTillDetailItemDto.fromJson(Map<String, dynamic> json) {
    return OutletTillDetailItemDto(
      tillId: json['tillId']?.toString() ?? '',
      tillName: json['tillName'] as String? ?? '',
      tillCode: json['tillCode'] as String? ?? '',
      status: json['status'] as String? ?? '',
      currentBalance: _nullableDecimal(json['currentBalance']),
      openingAmount: _nullableDecimal(json['openingAmount']),
      lastOpenedAt: json['lastOpenedAt']?.toString(),
      lastClosedAt: json['lastClosedAt']?.toString(),
      assignedCashierName: json['assignedCashierName'] as String?,
      deviceStatus: json['deviceStatus'] as String? ?? 'Offline',
    );
  }

  final String tillId;
  final String tillName;
  final String tillCode;
  final String status;
  final double? currentBalance;
  final double? openingAmount;
  final String? lastOpenedAt;
  final String? lastClosedAt;
  final String? assignedCashierName;
  final String deviceStatus;
}

double _decimal(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableDecimal(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

int _int(Object? value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
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
