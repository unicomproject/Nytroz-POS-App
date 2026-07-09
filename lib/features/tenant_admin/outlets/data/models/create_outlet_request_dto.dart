import '../../domain/entities/outlet_details.dart';

class CreateOutletRequestDto {
  const CreateOutletRequestDto({
    required this.outletName,
    required this.outletCode,
    required this.outletType,
    required this.status,
    required this.mainPhoneNumber,
    required this.emailAddress,
    this.managerId,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state,
    required this.country,
    required this.postalCode,
    required this.openingHours,
    required this.timezone,
  });

  factory CreateOutletRequestDto.fromForm(OutletFormData form) {
    return CreateOutletRequestDto(
      outletName: form.outletName,
      outletCode: form.outletCode,
      outletType: form.outletType,
      status: form.status,
      mainPhoneNumber: form.mainPhoneNumber,
      emailAddress: form.emailAddress,
      managerId: form.managerId,
      addressLine1: form.addressLine1,
      addressLine2: form.addressLine2,
      city: form.city,
      state: form.state,
      country: form.country,
      postalCode: form.postalCode,
      openingHours: form.openingHours,
      timezone: form.timezone,
    );
  }

  final String outletName;
  final String outletCode;
  final String outletType;
  final String status;
  final String mainPhoneNumber;
  final String emailAddress;
  final String? managerId;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? state;
  final String country;
  final String postalCode;
  final List<OutletOpeningHour> openingHours;
  final String timezone;

  Map<String, dynamic> toJson() {
    final businessHours = _businessHoursJson(openingHours);

    return {
      'outletName': outletName,
      'timezone': timezone,
      'status': _mapStatus(status),
      'outletType': _mapOutletType(outletType),
      'isDefaultOutlet': false,
      'phone': mainPhoneNumber,
      'email': emailAddress,
      'address': {
        'addressLine1': addressLine1,
        if (addressLine2 != null && addressLine2!.trim().isNotEmpty)
          'addressLine2': addressLine2,
        'city': city,
        if (state != null && state!.trim().isNotEmpty)
          'stateOrProvince': state,
        if (postalCode.trim().isNotEmpty) 'postalCode': postalCode,
        'countryCode': _normalizeCountryCode(country),
      },
      if (businessHours.isNotEmpty) 'businessHours': businessHours,
      'collectionEnabled': false,
    };
  }

  static String _mapStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return 'ACTIVE';
      case 'inactive':
        return 'INACTIVE';
      default:
        return status.trim().toUpperCase();
    }
  }

  static String _mapOutletType(String outletType) {
    switch (outletType.trim().toLowerCase()) {
      case 'retail':
      case 'store':
        return 'STORE';
      case 'warehouse':
        return 'WAREHOUSE';
      default:
        return outletType.trim().toUpperCase();
    }
  }

  static String _normalizeCountryCode(String country) {
    final code = country.trim().toUpperCase();
    return code.length == 2 ? code : 'LK';
  }

  static List<Map<String, dynamic>> _businessHoursJson(
    List<OutletOpeningHour> hours,
  ) {
    return [
      for (final hour in hours)
        if (!hour.closed &&
            hour.openTime.trim().isNotEmpty &&
            hour.closeTime.trim().isNotEmpty)
          {
            'dayOfWeek': _dayOfWeek(hour.day),
            'openingTime': _normalizeTime(hour.openTime),
            'closingTime': _normalizeTime(hour.closeTime),
            'isClosed': hour.closed,
          },
    ];
  }

  static int _dayOfWeek(String day) {
    switch (day.trim().toLowerCase()) {
      case 'sun':
        return 0;
      case 'mon':
        return 1;
      case 'tue':
        return 2;
      case 'wed':
        return 3;
      case 'thu':
        return 4;
      case 'fri':
        return 5;
      case 'sat':
        return 6;
      default:
        return 1;
    }
  }

  static String _normalizeTime(String time) {
    final trimmed = time.trim();
    if (trimmed.length == 5 && trimmed.contains(':')) {
      return '$trimmed:00';
    }

    return trimmed;
  }
}
