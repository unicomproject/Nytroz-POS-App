import '../../../domain/entities/pos_payment_method_type.dart';

class PaymentMethodCapability {
  const PaymentMethodCapability({
    required this.method,
    required this.executable,
    this.unavailableReason,
  });

  final PosPaymentMethodType method;
  final bool executable;
  final String? unavailableReason;
}

PaymentMethodCapability paymentMethodCapability(
  PosPaymentMethodType method, {
  required bool backendAllowed,
  required bool authoritativeSummary,
}) {
  if (!authoritativeSummary) {
    return PaymentMethodCapability(
      method: method,
      executable: false,
      unavailableReason: 'Checkout validation unavailable',
    );
  }
  if (!backendAllowed) {
    return PaymentMethodCapability(
      method: method,
      executable: false,
      unavailableReason: 'Not available for this sale',
    );
  }
  if (method == PosPaymentMethodType.cash) {
    return PaymentMethodCapability(method: method, executable: true);
  }
  return PaymentMethodCapability(
    method: method,
    executable: false,
    unavailableReason: switch (method) {
      PosPaymentMethodType.card => 'Payment provider unavailable',
      PosPaymentMethodType.qrMobile => 'QR Pay is coming soon',
      PosPaymentMethodType.split => 'Split Payment is coming soon',
      PosPaymentMethodType.cash => null,
    },
  );
}
