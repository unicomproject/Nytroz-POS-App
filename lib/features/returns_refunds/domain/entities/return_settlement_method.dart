import 'package:flutter/material.dart';

import '../../domain/entities/return_credit_preview.dart';

/// Settlement method options for Step 5 of the return flow.
///
class ReturnSettlementMethodOption {
  const ReturnSettlementMethodOption({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });

  final String code;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  static const cashRefund = ReturnSettlementMethodOption(
    code: 'CASH_REFUND',
    title: 'Cash Refund',
    description: 'Refund the amount in cash.',
    icon: Icons.payments_outlined,
    iconColor: Color(0xFF16A34A),
  );

  static const cardRefund = ReturnSettlementMethodOption(
    code: 'CARD_REFUND',
    title: 'Card Refund',
    description: 'Refund the amount to the original card.',
    icon: Icons.credit_card_outlined,
    iconColor: Color(0xFF2563EB),
  );

  static const storeCredit = ReturnSettlementMethodOption(
    code: 'STORE_CREDIT',
    title: 'Keep as Store Credit',
    description: 'Keep the amount as store credit for future use.',
    icon: Icons.storefront_outlined,
    iconColor: Color(0xFF7C3AED),
  );

  static const loyaltyPoints = ReturnSettlementMethodOption(
    code: 'LOYALTY_POINTS',
    title: 'Convert to Loyalty Points',
    description: 'Convert the credit amount to loyalty points.',
    icon: Icons.stars_rounded,
    iconColor: Color(0xFF2563EB),
  );

  static const List<ReturnSettlementMethodOption> options = [
    cashRefund,
    cardRefund,
    storeCredit,
    loyaltyPoints,
  ];

  static ReturnSettlementMethodOption? findByCode(String? code) {
    if (code == null || code.isEmpty) {
      return null;
    }

    for (final option in options) {
      if (option.code == code) {
        return option;
      }
    }

    return null;
  }

  bool isAvailableFor(ReturnCreditPreview preview) {
    if (code == 'CARD_REFUND') {
      final method = preview.paymentMethod.toLowerCase();
      return method == 'card' || preview.maskedCard.isNotEmpty;
    }

    if (code == 'STORE_CREDIT' || code == 'LOYALTY_POINTS') {
      final customerId = preview.customerId;
      return customerId != null && customerId.isNotEmpty;
    }

    return true;
  }

  ReturnSettlementPreviewValues previewFor(ReturnCreditPreview preview) {
    final netCredit = preview.calculation.netCreditAmount;

    switch (code) {
      case 'CARD_REFUND':
        return ReturnSettlementPreviewValues(
          previewTitle: 'Card Refund Preview',
          refundAmount: netCredit,
          customerCreditAmount: netCredit,
          refundMethodLabel: preview.paymentDisplay.isEmpty
              ? 'Card'
              : preview.paymentDisplay,
          settlementTypeLabel: title,
        );
      case 'STORE_CREDIT':
        return ReturnSettlementPreviewValues(
          previewTitle: 'Store Credit Preview',
          refundAmount: 0,
          customerCreditAmount: netCredit,
          refundMethodLabel: 'Store Credit',
          settlementTypeLabel: title,
        );
      case 'LOYALTY_POINTS':
        return ReturnSettlementPreviewValues(
          previewTitle: 'Loyalty Points Preview',
          refundAmount: 0,
          customerCreditAmount: netCredit,
          refundMethodLabel: 'Loyalty Points',
          settlementTypeLabel: title,
        );
      case 'CASH_REFUND':
      default:
        return ReturnSettlementPreviewValues(
          previewTitle: 'Cash Refund Preview',
          refundAmount: netCredit,
          customerCreditAmount: netCredit,
          refundMethodLabel: 'Cash',
          settlementTypeLabel: title,
        );
    }
  }
}

class ReturnSettlementPreviewValues {
  const ReturnSettlementPreviewValues({
    required this.previewTitle,
    required this.refundAmount,
    required this.customerCreditAmount,
    required this.refundMethodLabel,
    required this.settlementTypeLabel,
  });

  final String previewTitle;
  final double refundAmount;
  final double customerCreditAmount;
  final String refundMethodLabel;
  final String settlementTypeLabel;
}
