class PosCustomer {
  const PosCustomer({
    required this.customerId,
    required this.fullName,
    this.phone,
    this.email,
    this.status = '',
  });

  final String customerId;
  final String fullName;
  final String? phone;
  final String? email;
  final String status;

  String get displayName =>
      fullName.trim().isEmpty ? 'Customer' : fullName.trim();

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'status': status,
    };
  }
}
