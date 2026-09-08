import 'package:flutter/material.dart';

import '../../providers/pos_checkout_summary_provider.dart';

abstract final class PaymentMethodStyle {
  static const background = Color(0xFF050505);
  @Deprecated('Use Theme.of(context).colorScheme.primary instead')
  static const orange = Color(0xFFFF6A00);
  static const border = Color(0xFFE2E6ED);
  static const navy = Color(0xFF06235D);
  static const subtleBackground = Color(0xFFF8FAFC);
  static const panelRadius = 14.0;
  static const gap = 12.0;
  static const padding = 18.0;

  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
}

String paymentMoney(int value, [String currency = '']) {
  final formatted = formatCheckoutMoney(currency, value.abs());
  return value < 0 ? '- $formatted' : formatted;
}
