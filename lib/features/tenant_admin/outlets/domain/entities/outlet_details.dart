class OutletDetails {
  const OutletDetails({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.status,
    this.outletType,
    this.imageUrl,
    this.imageMediaAssetId,
    this.isDefaultOutlet = false,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.countryCode,
    this.postalCode,
    this.businessHours = const [],
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
    this.todaySalesTrendLabel,
    this.weekSalesAmount,
    this.weekSalesCurrency,
    this.weekSalesTrendLabel,
    this.performancePoints = const [],
    this.metrics = const [],
    this.assignedTills = const [],
    this.staff = const [],
    this.needsAttention = const [],
    this.timezone,
  });

  final String id;
  final String name;
  final String code;
  final String address;
  final String status;
  final String? outletType;
  final String? imageUrl;
  final String? imageMediaAssetId;
  final bool isDefaultOutlet;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? countryCode;
  final String? postalCode;
  final List<OutletOpeningHour> businessHours;
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
  final String? todaySalesTrendLabel;
  final double? weekSalesAmount;
  final String? weekSalesCurrency;
  final String? weekSalesTrendLabel;
  final List<OutletPerformancePoint> performancePoints;
  final List<OutletDetailMetric> metrics;
  final List<OutletRelatedItem> assignedTills;
  final List<OutletRelatedItem> staff;
  final List<OutletAttentionItem> needsAttention;

  String? get todaySalesDisplay {
    if (todaySalesAmount == null) {
      return null;
    }

    return _formatMoney(todaySalesAmount!, todaySalesCurrency);
  }

  String? get weekSalesDisplay {
    if (weekSalesAmount == null) {
      return null;
    }

    return _formatMoney(weekSalesAmount!, weekSalesCurrency);
  }

  String get managerDisplay {
    if (managerName != null && managerName!.trim().isNotEmpty) {
      return managerName!;
    }

    return 'Not assigned';
  }

  String? get managerContact {
    if (managerPhone != null && managerPhone!.trim().isNotEmpty) {
      return managerPhone;
    }

    if (phone != null && phone!.trim().isNotEmpty) {
      return phone;
    }

    return null;
  }
}

class OutletPerformancePoint {
  const OutletPerformancePoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class OutletDetailMetric {
  const OutletDetailMetric({
    required this.title,
    required this.value,
    this.subtitle,
    this.iconKey,
  });

  final String title;
  final String value;
  final String? subtitle;
  final String? iconKey;
}

class OutletRelatedItem {
  const OutletRelatedItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.status,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? status;
}

class OutletAttentionItem {
  const OutletAttentionItem({
    required this.title,
    required this.message,
    this.status,
    this.route,
  });

  final String title;
  final String message;
  final String? status;
  final String? route;
}

class OutletFormData {
  const OutletFormData({
    required this.outletName,
    this.outletCode = '',
    required this.outletType,
    required this.status,
    required this.mainPhoneNumber,
    required this.emailAddress,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.imageUrl,
    this.imageMediaAssetId,
    this.imageOperation = OutletImageOperation.keep,
    this.isDefaultOutlet = false,
    this.managerId,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state,
    required this.country,
    required this.postalCode,
    required this.openingHours,
    this.timezone = 'Asia/Colombo',
  });

  final String outletName;
  final String outletCode;
  final String outletType;
  final String status;
  final String mainPhoneNumber;
  final String emailAddress;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? imageUrl;
  final String? imageMediaAssetId;
  final OutletImageOperation imageOperation;
  final bool isDefaultOutlet;
  final String? managerId;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? state;
  final String country;
  final String postalCode;
  final List<OutletOpeningHour> openingHours;
  final String timezone;
}

enum OutletImageOperation { keep, replace, remove }

class OutletOpeningHour {
  const OutletOpeningHour({
    required this.day,
    required this.openTime,
    required this.closeTime,
    required this.closed,
  });

  final String day;
  final String openTime;
  final String closeTime;
  final bool closed;
}

String _formatMoney(double amount, String? currency) {
  final symbol = _currencySymbol(currency);
  final formatted =
      amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
  return '$symbol$formatted';
}

String _currencySymbol(String? currency) {
  switch (currency?.toUpperCase()) {
    case 'GBP':
      return '£';
    case 'EUR':
      return '€';
    case 'USD':
      return '\$';
    case 'LKR':
      return 'Rs ';
    default:
      return currency == null || currency.isEmpty ? '' : '$currency ';
  }
}
