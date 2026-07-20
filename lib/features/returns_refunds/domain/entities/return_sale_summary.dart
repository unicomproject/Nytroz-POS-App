class ReturnSaleSummary {
  const ReturnSaleSummary({
    required this.saleId,
    required this.invoiceNo,
    this.customerId,
    required this.customerName,
    required this.phone,
    required this.paymentMethod,
    required this.maskedCard,
    this.saleDate,
    required this.total,
    required this.itemCount,
    required this.currency,
  });

  final String saleId;
  final String invoiceNo;
  final String? customerId;
  final String customerName;
  final String phone;
  final String paymentMethod;
  final String maskedCard;
  final DateTime? saleDate;
  final double total;
  final int itemCount;
  final String currency;

  factory ReturnSaleSummary.fromJson(Map<String, dynamic> json) {
    return ReturnSaleSummary(
      saleId: _readString(json, 'saleId'),
      invoiceNo: _readString(json, 'invoiceNo'),
      customerId: _readNullableString(json, 'customerId'),
      customerName: _readString(json, 'customerName'),
      phone: _readString(json, 'phone'),
      paymentMethod: _readString(json, 'paymentMethod'),
      maskedCard: _readString(json, 'maskedCard'),
      saleDate: _readDateTime(json['saleDate']),
      total: _readDouble(json, 'total'),
      itemCount: _readInt(json, 'itemCount'),
      currency: _readString(json, 'currency'),
    );
  }

  String get paymentDisplay {
    if (maskedCard.isNotEmpty && paymentMethod.isNotEmpty) {
      return '$paymentMethod $maskedCard';
    }
    if (paymentMethod.isNotEmpty) {
      return paymentMethod;
    }
    return maskedCard;
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  static String? _readNullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value.toLocal();
    }
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}

class ReturnSaleSearchPage {
  const ReturnSaleSearchPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    this.paymentMethods = const [],
  });

  final List<ReturnSaleSummary> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final List<ReturnPaymentMethodFilterOption> paymentMethods;

  factory ReturnSaleSearchPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final items = itemsJson is List
        ? itemsJson
            .whereType<Map<String, dynamic>>()
            .map(ReturnSaleSummary.fromJson)
            .toList(growable: false)
        : const <ReturnSaleSummary>[];
    final paymentMethodsJson = json['paymentMethods'];
    final paymentMethods = paymentMethodsJson is List
        ? paymentMethodsJson
            .whereType<Map<String, dynamic>>()
            .map(ReturnPaymentMethodFilterOption.fromJson)
            .where((option) => option.code.isNotEmpty)
            .toList(growable: false)
        : const <ReturnPaymentMethodFilterOption>[];

    return ReturnSaleSearchPage(
      items: items,
      page: _readInt(json, 'page'),
      pageSize: _readInt(json, 'pageSize'),
      totalCount: _readInt(json, 'totalCount'),
      paymentMethods: paymentMethods,
    );
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ReturnPaymentMethodFilterOption {
  const ReturnPaymentMethodFilterOption({
    required this.code,
    required this.label,
  });

  final String code;
  final String label;

  factory ReturnPaymentMethodFilterOption.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReturnPaymentMethodFilterOption(
      code: (json['code'] ?? '').toString().trim(),
      label: (json['label'] ?? '').toString().trim(),
    );
  }
}
