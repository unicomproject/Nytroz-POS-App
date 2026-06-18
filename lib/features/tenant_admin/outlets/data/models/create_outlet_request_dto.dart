import '../../domain/entities/outlet_details.dart';

class CreateOutletRequestDto {
  const CreateOutletRequestDto({
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

  factory CreateOutletRequestDto.fromForm(OutletFormData form) {
    return CreateOutletRequestDto(
      outletName: form.outletName,
      outletCode: form.outletCode,
      outletType: form.outletType,
      mainPhoneNumber: form.mainPhoneNumber,
      emailAddress: form.emailAddress,
      managerId: form.managerId,
      addressLine1: form.addressLine1,
      addressLine2: form.addressLine2,
      city: form.city,
      country: form.country,
      postalCode: form.postalCode,
      openingHours: form.openingHours,
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'name': outletName,
      'code': outletCode,
      'addressLine1': addressLine1,
      if (addressLine2 != null && addressLine2!.trim().isNotEmpty)
        'addressLine2': addressLine2,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'phone': mainPhoneNumber,
      'email': emailAddress,
      'status': 'Active',
    };
  }
}
