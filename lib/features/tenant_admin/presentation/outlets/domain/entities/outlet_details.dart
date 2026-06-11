class OutletDetails {
  const OutletDetails({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.status,
    this.managerName,
    this.managerPhone,
    this.openingHours,
    this.todaysStatus,
    this.metrics = const [],
    this.assignedTills = const [],
    this.staff = const [],
    this.needsAttention = const [],
  });

  final String id;
  final String name;
  final String code;
  final String address;
  final String status;
  final String? managerName;
  final String? managerPhone;
  final String? openingHours;
  final String? todaysStatus;
  final List<OutletDetailMetric> metrics;
  final List<OutletRelatedItem> assignedTills;
  final List<OutletRelatedItem> staff;
  final List<OutletAttentionItem> needsAttention;
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
  });

  final String title;
  final String message;
  final String? status;
}

class OutletFormData {
  const OutletFormData({
    required this.outletName,
    required this.outletCode,
    required this.outletType,
    required this.mainPhoneNumber,
    required this.emailAddress,
    this.managerId,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.country,
    required this.postalCode,
    required this.openingHours,
  });

  final String outletName;
  final String outletCode;
  final String outletType;
  final String mainPhoneNumber;
  final String emailAddress;
  final String? managerId;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String country;
  final String postalCode;
  final List<OutletOpeningHour> openingHours;
}

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
