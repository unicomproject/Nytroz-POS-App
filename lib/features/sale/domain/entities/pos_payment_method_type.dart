import 'package:flutter/material.dart';

import '../../../../core/access/pos_access_codes.dart';

enum PosPaymentMethodType {
  cash,
  card,
  qrMobile,
  split,
}

extension PosPaymentMethodTypeX on PosPaymentMethodType {
  String get title {
    return switch (this) {
      PosPaymentMethodType.cash => 'Cash',
      PosPaymentMethodType.card => 'Card',
      PosPaymentMethodType.qrMobile => 'QR Payment',
      PosPaymentMethodType.split => 'Split Payment',
    };
  }

  String get continueButtonLabel => 'Continue with $title';

  String get description {
    return switch (this) {
      PosPaymentMethodType.cash => 'Pay with cash',
      PosPaymentMethodType.card => 'Debit / Credit card',
      PosPaymentMethodType.qrMobile => 'Scan to pay',
      PosPaymentMethodType.split => 'Multiple payment methods',
    };
  }

  IconData get icon {
    return switch (this) {
      PosPaymentMethodType.cash => Icons.payments_outlined,
      PosPaymentMethodType.card => Icons.credit_card_rounded,
      PosPaymentMethodType.qrMobile => Icons.qr_code_2_rounded,
      PosPaymentMethodType.split => Icons.sync_alt_rounded,
    };
  }

  Color get tintColor {
    return switch (this) {
      PosPaymentMethodType.cash => const Color(0xFFF1FBF5),
      PosPaymentMethodType.card => const Color(0xFFF3F6FF),
      PosPaymentMethodType.qrMobile => const Color(0xFFF7F3FF),
      PosPaymentMethodType.split => const Color(0xFFFFF7EF),
    };
  }

  Color get accentColor {
    return switch (this) {
      PosPaymentMethodType.cash => const Color(0xFF15803D),
      PosPaymentMethodType.card => const Color(0xFF2563EB),
      PosPaymentMethodType.qrMobile => const Color(0xFF7C3AED),
      PosPaymentMethodType.split => const Color(0xFFEA580C),
    };
  }

  String get permissionCode {
    return switch (this) {
      PosPaymentMethodType.cash => PosPermissionCodes.acceptCashPayment,
      PosPaymentMethodType.card => PosPermissionCodes.acceptCardPayment,
      PosPaymentMethodType.qrMobile => PosPermissionCodes.acceptQrPayment,
      PosPaymentMethodType.split => PosPermissionCodes.acceptSplitPayment,
    };
  }

  String get paymentRoutePath {
    return switch (this) {
      PosPaymentMethodType.cash => '/pos/new-sale/payment/cash',
      PosPaymentMethodType.card => '/pos/new-sale/payment/card',
      PosPaymentMethodType.qrMobile => '/pos/new-sale/payment/qr',
      PosPaymentMethodType.split => '/pos/new-sale/payment/split',
    };
  }
}

List<PosPaymentMethodType> allowedPosPaymentMethods(
    Set<String> permissionCodes) {
  return PosPaymentMethodType.values
      .where((method) => permissionCodes.contains(method.permissionCode))
      .toList(growable: false);
}
