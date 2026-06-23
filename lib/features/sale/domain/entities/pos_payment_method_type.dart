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
      PosPaymentMethodType.qrMobile => 'QR / Mobile Payment',
      PosPaymentMethodType.split => 'Split Payment',
    };
  }

  String get continueButtonLabel => 'Continue with $title';

  IconData get icon {
    return switch (this) {
      PosPaymentMethodType.cash => Icons.payments_outlined,
      PosPaymentMethodType.card => Icons.credit_card_rounded,
      PosPaymentMethodType.qrMobile => Icons.qr_code_2_rounded,
      PosPaymentMethodType.split => Icons.call_split_rounded,
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

List<PosPaymentMethodType> allowedPosPaymentMethods(Set<String> permissionCodes) {
  return PosPaymentMethodType.values
      .where((method) => permissionCodes.contains(method.permissionCode))
      .toList(growable: false);
}
