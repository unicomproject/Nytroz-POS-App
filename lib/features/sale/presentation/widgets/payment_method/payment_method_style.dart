import 'package:flutter/material.dart';

import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';

abstract final class PaymentMethodStyle {
  static const background = Color(0xFF050505);
  static const orange = Color(0xFFFF3214);
  static const border = Color(0xFFE2E6ED);
  static const navy = Color(0xFF06235D);
  static const panelRadius = 14.0;
  static const gap = 12.0;
  static const padding = 18.0;
}

String paymentMoney(int value) {
  return value < 0 ? '- ${formatLkr(value.abs())}' : formatLkr(value);
}
