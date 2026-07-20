import 'package:flutter/material.dart';

import 'refund_method_type.dart';

class ReturnRefundMethodOption {
  const ReturnRefundMethodOption({
    required this.code,
    required this.displayName,
    required this.enabled,
    this.disabledReason,
    this.originalPaymentMethod,
    this.maskedReference,
    this.requiresOpenTill = false,
    this.requiresProvider = false,
    this.requiresApproval = false,
  });

  final String code;
  final String displayName;
  final bool enabled;
  final String? disabledReason;
  final String? originalPaymentMethod;
  final String? maskedReference;
  final bool requiresOpenTill;
  final bool requiresProvider;
  final bool requiresApproval;

  RefundMethodType? get refundMethodType {
    switch (code.trim().toUpperCase()) {
      case 'ORIGINAL_PAYMENT':
        return RefundMethodType.originalPaymentMethod;
      case 'CASH':
        return RefundMethodType.cash;
      case 'STORE_CREDIT':
        return RefundMethodType.storeCredit;
      default:
        return null;
    }
  }

  String get description {
    if (maskedReference != null && maskedReference!.trim().isNotEmpty) {
      final method = originalPaymentMethod?.trim() ?? '';
      if (method.isNotEmpty) {
        return '$method $maskedReference';
      }
      return maskedReference!.trim();
    }
    if (originalPaymentMethod != null && originalPaymentMethod!.trim().isNotEmpty) {
      return originalPaymentMethod!.trim();
    }
    return disabledReason?.trim() ?? '';
  }

  IconData get icon {
    switch (code.trim().toUpperCase()) {
      case 'ORIGINAL_PAYMENT':
        return Icons.credit_card_outlined;
      case 'CASH':
        return Icons.payments_outlined;
      case 'STORE_CREDIT':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  factory ReturnRefundMethodOption.fromJson(Map<String, dynamic> json) {
    return ReturnRefundMethodOption(
      code: json['code']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      enabled: json['enabled'] == true,
      disabledReason: json['disabledReason']?.toString(),
      originalPaymentMethod: json['originalPaymentMethod']?.toString(),
      maskedReference: json['maskedReference']?.toString(),
      requiresOpenTill: json['requiresOpenTill'] == true,
      requiresProvider: json['requiresProvider'] == true,
      requiresApproval: json['requiresApproval'] == true,
    );
  }
}

class ReturnRefundMethodsResponse {
  const ReturnRefundMethodsResponse({
    required this.items,
    this.defaultMethodCode,
    this.selectedMethodCode,
    this.selectedAt,
  });

  final List<ReturnRefundMethodOption> items;
  final String? defaultMethodCode;
  final String? selectedMethodCode;
  final DateTime? selectedAt;

  factory ReturnRefundMethodsResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return ReturnRefundMethodsResponse(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(ReturnRefundMethodOption.fromJson)
              .toList(growable: false)
          : const [],
      defaultMethodCode: json['defaultMethodCode']?.toString(),
      selectedMethodCode: json['selectedMethodCode']?.toString(),
      selectedAt: DateTime.tryParse(json['selectedAt']?.toString() ?? ''),
    );
  }
}

class ReturnRefundMethodSaveResponse {
  const ReturnRefundMethodSaveResponse({
    required this.saleId,
    required this.methodCode,
    required this.selectedAt,
  });

  final String saleId;
  final String methodCode;
  final DateTime selectedAt;

  factory ReturnRefundMethodSaveResponse.fromJson(Map<String, dynamic> json) {
    return ReturnRefundMethodSaveResponse(
      saleId: json['saleId']?.toString() ?? '',
      methodCode: json['methodCode']?.toString() ?? '',
      selectedAt: DateTime.tryParse(json['selectedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
