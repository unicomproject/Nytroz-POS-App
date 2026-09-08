class PosCustomer {
  const PosCustomer({
    required this.customerId,
    required this.fullName,
    this.phone,
    this.email,
    this.status = '',
    this.customerCode,
    this.sourceType,
    this.joinedAt,
    this.totalOrderCount = 0,
    this.totalSpentAmount,
    this.currencyCode,
    this.isMixedCurrencySpend = false,
    this.lastPurchaseAt,
  });

  final String customerId;
  final String fullName;
  final String? phone;
  final String? email;
  final String status;
  final String? customerCode;
  final String? sourceType;
  final DateTime? joinedAt;
  final int totalOrderCount;
  final double? totalSpentAmount;
  final String? currencyCode;
  final bool isMixedCurrencySpend;
  final DateTime? lastPurchaseAt;

  String get displayName =>
      fullName.trim().isEmpty ? 'Customer' : fullName.trim();

  bool get isActive {
    final normalized = status.trim().toUpperCase();
    return normalized == 'ACTIVE' || normalized == 'A';
  }

  String get statusLabel {
    if (status.trim().isEmpty) {
      return 'Unknown';
    }
    final normalized = status.trim().toUpperCase();
    if (normalized == 'BLOCKED') {
      return 'Blocked';
    }
    return isActive ? 'Active' : 'Inactive';
  }

  String get sourceLabel {
    final source = sourceType?.trim() ?? '';
    return source.isEmpty ? '—' : source;
  }

  String get ordersDisplay => totalOrderCount.toString();

  String get spentDisplay {
    if (isMixedCurrencySpend || totalSpentAmount == null) {
      return '—';
    }
    final amount = totalSpentAmount!.toStringAsFixed(2);
    final currency = currencyCode?.trim();
    if (currency != null && currency.isNotEmpty) {
      return '$currency $amount';
    }
    return amount;
  }

  String get averageOrderValueDisplay {
    if (isMixedCurrencySpend ||
        totalSpentAmount == null ||
        totalOrderCount <= 0) {
      return '—';
    }
    final average = (totalSpentAmount! / totalOrderCount).toStringAsFixed(2);
    final currency = currencyCode?.trim();
    return currency == null || currency.isEmpty
        ? average
        : '$currency $average';
  }

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get shortCustomerId {
    final code = customerCode?.trim();
    if (code != null && code.isNotEmpty) {
      return code;
    }
    final id = customerId.trim();
    if (id.isEmpty) {
      return '—';
    }
    if (id.length <= 12) {
      return id;
    }
    return '${id.substring(0, 8)}…';
  }

  factory PosCustomer.fromJson(Map<String, dynamic> json) {
    return PosCustomer(
      customerId: json['customerId']?.toString() ??
          json['CustomerId']?.toString() ??
          '',
      fullName:
          json['fullName']?.toString() ?? json['FullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['Phone']?.toString(),
      email: json['email']?.toString() ?? json['Email']?.toString(),
      status: json['status']?.toString() ?? json['Status']?.toString() ?? '',
      customerCode:
          json['customerCode']?.toString() ?? json['CustomerCode']?.toString(),
      sourceType:
          json['sourceType']?.toString() ?? json['SourceType']?.toString(),
      joinedAt: _readDate(json['joinedAt'] ?? json['JoinedAt']),
      totalOrderCount: _readInt(
        json['totalOrderCount'] ?? json['TotalOrderCount'],
      ),
      totalSpentAmount: _readOptionalDouble(
        json['totalSpentAmount'] ?? json['TotalSpentAmount'],
      ),
      currencyCode:
          json['currencyCode']?.toString() ?? json['CurrencyCode']?.toString(),
      isMixedCurrencySpend: _readBool(
        json['isMixedCurrencySpend'] ?? json['IsMixedCurrencySpend'],
      ),
      lastPurchaseAt:
          _readDate(json['lastPurchaseAt'] ?? json['LastPurchaseAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'status': status,
      'customerCode': customerCode,
      'sourceType': sourceType,
      'joinedAt': joinedAt?.toIso8601String(),
      'totalOrderCount': totalOrderCount,
      'totalSpentAmount': totalSpentAmount,
      'currencyCode': currencyCode,
      'isMixedCurrencySpend': isMixedCurrencySpend,
      'lastPurchaseAt': lastPurchaseAt?.toIso8601String(),
    };
  }
}

class PosCustomerOrder {
  const PosCustomerOrder({
    required this.orderId,
    required this.orderNumber,
    required this.orderDate,
    required this.totalAmount,
    required this.currencyCode,
    required this.status,
    this.outletDisplayName,
    this.tillName,
  });

  final String orderId;
  final String orderNumber;
  final DateTime? orderDate;
  final double? totalAmount;
  final String currencyCode;
  final String status;
  final String? outletDisplayName;
  final String? tillName;

  factory PosCustomerOrder.fromJson(Map<String, dynamic> json) {
    return PosCustomerOrder(
      orderId: json['orderId']?.toString() ?? json['OrderId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ??
          json['OrderNumber']?.toString() ??
          '',
      orderDate: _readDate(json['orderDate'] ?? json['OrderDate']),
      totalAmount: _readOptionalDouble(json['totalAmount'] ?? json['TotalAmount']),
      currencyCode: json['currencyCode']?.toString() ??
          json['CurrencyCode']?.toString() ??
          '',
      status: json['status']?.toString() ?? json['Status']?.toString() ?? '',
      outletDisplayName: json['outletDisplayName']?.toString() ??
          json['OutletDisplayName']?.toString(),
      tillName: json['tillName']?.toString() ?? json['TillName']?.toString(),
    );
  }
}

class PosCustomerSummary {
  const PosCustomerSummary({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.customersWithOrders,
    required this.newCustomersThisMonth,
    this.timeZoneId = 'UTC',
  });

  final int totalCustomers;
  final int activeCustomers;
  final int customersWithOrders;
  final int newCustomersThisMonth;
  final String timeZoneId;

  factory PosCustomerSummary.fromJson(Map<String, dynamic> json) {
    return PosCustomerSummary(
      totalCustomers:
          _readInt(json['totalCustomers'] ?? json['TotalCustomers']),
      activeCustomers:
          _readInt(json['activeCustomers'] ?? json['ActiveCustomers']),
      customersWithOrders: _readInt(
        json['customersWithOrders'] ?? json['CustomersWithOrders'],
      ),
      newCustomersThisMonth: _readInt(
        json['newCustomersThisMonth'] ?? json['NewCustomersThisMonth'],
      ),
      timeZoneId: json['timeZoneId']?.toString() ??
          json['TimeZoneId']?.toString() ??
          'UTC',
    );
  }
}

class PosCustomerAttachResult {
  const PosCustomerAttachResult({
    required this.customer,
    this.saleId,
    this.attachmentMode = 'CART_CONTEXT',
  });

  final PosCustomer customer;
  final String? saleId;
  final String attachmentMode;

  factory PosCustomerAttachResult.fromJson(Map<String, dynamic> json) {
    return PosCustomerAttachResult(
      customer: PosCustomer.fromJson(json),
      saleId: json['saleId']?.toString() ?? json['SaleId']?.toString(),
      attachmentMode: json['attachmentMode']?.toString() ??
          json['AttachmentMode']?.toString() ??
          'CART_CONTEXT',
    );
  }
}

DateTime? _readDate(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value.toLocal();
  }
  return DateTime.tryParse(value.toString())?.toLocal();
}

int _readInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _readOptionalDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}
