/// Membership tier shown on POS customer rows. Tenant-scoped loyalty data is
/// owned by the backend; the POS UI only renders the resolved tier.
enum PosMembershipTier { gold, silver, bronze, none }

/// Read model for a customer shown in the New Sale "Add Customer" flow.
///
/// Customer records are tenant-scoped. This entity intentionally carries only
/// the fields the cashier UI needs (no e-commerce profile data).
class PosCustomer {
  const PosCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.membershipTier,
    required this.loyaltyPoints,
    this.email,
    this.dateOfBirth,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final PosMembershipTier membershipTier;
  final int loyaltyPoints;
  final DateTime? dateOfBirth;

  /// Up to two uppercase initials derived from the customer name.
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Case-insensitive match against name, phone (digits only) or email.
  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    if (name.toLowerCase().contains(normalized)) {
      return true;
    }

    if (email != null && email!.toLowerCase().contains(normalized)) {
      return true;
    }

    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    final queryDigits = normalized.replaceAll(RegExp(r'\D'), '');
    if (queryDigits.isNotEmpty && phoneDigits.contains(queryDigits)) {
      return true;
    }

    return phone.toLowerCase().contains(normalized);
  }
}
