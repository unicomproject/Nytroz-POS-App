import '../../domain/entities/pos_customer.dart';

/// Maps the backend customer payload (`CustomerSearchResponse` /
/// `CreateCustomerResponse`) into the [PosCustomer] read model used by the UI.
///
/// The current backend customer DTO exposes id/name/phone/email/status only.
/// Loyalty tier and points live on a separate loyalty module and are not part
/// of this payload, so they default to none/0 until that API is wired.
class PosCustomerDto {
  const PosCustomerDto._();

  static PosCustomer fromJson(Map<String, dynamic> json) {
    final name = json['fullName']?.toString().trim();
    final phone = json['phone']?.toString().trim();
    final email = json['email']?.toString().trim();

    return PosCustomer(
      id: json['customerId']?.toString() ?? json['id']?.toString() ?? '',
      name: (name == null || name.isEmpty) ? 'Customer' : name,
      phone: phone ?? '',
      email: (email == null || email.isEmpty) ? null : email,
      membershipTier: PosMembershipTier.none,
      loyaltyPoints: 0,
    );
  }
}
