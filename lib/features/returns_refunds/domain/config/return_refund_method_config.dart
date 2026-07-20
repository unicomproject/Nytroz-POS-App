import 'package:flutter/material.dart';

import '../entities/refund_method_type.dart';
import '../entities/return_credit_preview.dart';

class RefundMethodOption {
  const RefundMethodOption({
    required this.type,
    required this.title,
    this.description,
    required this.icon,
    this.enabled = true,
  });

  final RefundMethodType type;
  final String title;
  final String? description;
  final IconData icon;
  final bool enabled;
}

/// Approved frontend refund-method catalog for the refund branch.
abstract final class ReturnRefundMethodConfig {
  static List<RefundMethodOption> availableMethods({
    required ReturnCreditPreview? preview,
  }) {
    final methods = <RefundMethodOption>[];

    if (preview != null && preview.paymentMethod.trim().isNotEmpty) {
      methods.add(
        RefundMethodOption(
          type: RefundMethodType.originalPaymentMethod,
          title: 'Original Payment Method',
          description: preview.paymentDisplay.trim().isEmpty
              ? preview.paymentMethod.trim()
              : preview.paymentDisplay.trim(),
          icon: Icons.credit_card_outlined,
        ),
      );
    }

    methods.addAll(const [
      RefundMethodOption(
        type: RefundMethodType.cash,
        title: 'Cash',
        icon: Icons.payments_outlined,
      ),
      RefundMethodOption(
        type: RefundMethodType.storeCredit,
        title: 'Store Credit',
        description: 'Issue as store credit',
        icon: Icons.card_giftcard_outlined,
      ),
    ]);

    return methods;
  }
}
