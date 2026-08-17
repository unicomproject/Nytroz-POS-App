import '../../domain/entities/outlet_details.dart';

class CreateOutletRequestDto {
  const CreateOutletRequestDto({
    required this.outletName,
    required this.outletType,
    required this.status,
    required this.mainPhoneNumber,
    required this.emailAddress,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.imageMediaAssetId,
    this.imageOperation = OutletImageOperation.keep,
    required this.isDefaultOutlet,
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
      outletName: form.outletName.trim(),
      outletType: form.outletType.trim(),
      status: form.status.trim(),
      mainPhoneNumber: form.mainPhoneNumber.trim(),
      emailAddress: form.emailAddress.trim(),
      contactName: form.contactName,
      contactPhone: form.contactPhone,
      contactEmail: form.contactEmail,
      imageMediaAssetId: form.imageMediaAssetId,
      imageOperation: form.imageOperation,
      isDefaultOutlet: form.isDefaultOutlet,
      managerId: form.managerId,
      addressLine1: form.addressLine1.trim(),
      addressLine2: form.addressLine2,
      city: form.city.trim(),
      state: form.state,
      country: form.country.trim(),
      postalCode: form.postalCode.trim(),
      openingHours: form.openingHours,
      timezone: form.timezone.trim(),
    );
  }

  final String outletName;
  final String outletType;
  final String status;
  final String mainPhoneNumber;
  final String emailAddress;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
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

  Map<String, dynamic> toJson() {
    final businessHours = _businessHoursJson(openingHours);

    return {
      'outletName': outletName.trim(),
      'timezone': timezone.trim(),
      'status': _mapStatus(status),
      'outletType': _mapOutletType(outletType),
      'isDefaultOutlet': isDefaultOutlet,
      if (_nullable(mainPhoneNumber) != null)
        'phone': _nullable(mainPhoneNumber),
      if (_nullable(emailAddress) != null) 'email': _nullable(emailAddress),
      'address': {
        'addressLine1': addressLine1,
        if (addressLine2 != null && addressLine2!.trim().isNotEmpty)
          'addressLine2': addressLine2!.trim(),
        'city': city,
        if (state != null && state!.trim().isNotEmpty)
          'stateOrProvince': state!.trim(),
        if (postalCode.trim().isNotEmpty) 'postalCode': postalCode.trim(),
        'countryCode': _normalizeCountryCode(country),
        if (_nullable(contactName) != null)
          'contactName': _nullable(contactName),
        if (_nullable(contactPhone) != null)
          'contactPhone': _nullable(contactPhone),
        if (_nullable(contactEmail) != null)
          'contactEmail': _nullable(contactEmail),
      },
      if (_nullable(imageMediaAssetId) != null)
        'imageMediaAssetId': _nullable(imageMediaAssetId),
      if (businessHours.isNotEmpty) 'businessHours': businessHours,
      'collectionEnabled': false,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final json = toJson();
    json['imageOperation'] = switch (imageOperation) {
      OutletImageOperation.keep => 'KEEP',
      OutletImageOperation.replace => 'REPLACE',
      OutletImageOperation.remove => 'REMOVE',
    };
    if (imageOperation != OutletImageOperation.replace) {
      json.remove('imageMediaAssetId');
    }
    return json;
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
    return country.trim().toUpperCase();
  }

  static List<Map<String, dynamic>> _businessHoursJson(
    List<OutletOpeningHour> hours,
  ) {
    return [
      for (final hour in hours)
        {
          'dayOfWeek': _dayOfWeek(hour.day),
          if (!hour.closed) 'openingTime': _normalizeTime(hour.openTime),
          if (!hour.closed) 'closingTime': _normalizeTime(hour.closeTime),
          'isClosed': hour.closed,
        },
    ];
  }

  static int _dayOfWeek(String day) {
    switch (day.trim().toLowerCase()) {
      case 'sun':
      case 'sunday':
        return 0;
      case 'mon':
      case 'monday':
        return 1;
      case 'tue':
      case 'tuesday':
        return 2;
      case 'wed':
      case 'wednesday':
        return 3;
      case 'thu':
      case 'thursday':
        return 4;
      case 'fri':
      case 'friday':
        return 5;
      case 'sat':
      case 'saturday':
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

    final lower = trimmed.toLowerCase();
    if (lower.contains('am') || lower.contains('pm')) {
      try {
        final isPm = lower.contains('pm');
        final timePart = lower.replaceAll('am', '').replaceAll('pm', '').trim();
        final parts = timePart.split(':');
        int hours = int.parse(parts[0].trim());
        final minutes = parts[1].trim();
        if (isPm && hours < 12) hours += 12;
        if (!isPm && hours == 12) hours = 0;
        return '${hours.toString().padLeft(2, '0')}:$minutes:00';
      } catch (_) {}
    }

    return trimmed;
  }

  static String? _nullable(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
