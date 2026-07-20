import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/refund_method_type.dart';
import '../../../domain/entities/return_credit_preview.dart';
import '../../../domain/entities/return_settlement_method.dart';

class RefundSettlementDetailsCard extends StatelessWidget {
  const RefundSettlementDetailsCard({
    super.key,
    required this.preview,
    required this.refundMethod,
    required this.settlementMethodCode,
    this.transactionReference,
  });

  final ReturnCreditPreview preview;
  final RefundMethodType? refundMethod;
  final String? settlementMethodCode;
  final String? transactionReference;

  @override
  Widget build(BuildContext context) {
    final methodTitle = _methodTitle();
    final paymentDetail = _paymentDetail();
    final settlement =
        ReturnSettlementMethodOption.findByCode(settlementMethodCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Settlement Details',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: TenantAdminColors.secondary,
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                ),
                child: Icon(
                  settlement?.icon ?? Icons.payments_outlined,
                  color: settlement?.iconColor ?? TenantAdminColors.primary,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      methodTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (paymentDetail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        paymentDetail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TenantAdminColors.mutedText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (transactionReference != null &&
              transactionReference!.trim().isNotEmpty) ...[
            const SizedBox(height: TenantAdminSpacing.lg),
            Text(
              'Transaction ID',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              transactionReference!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _methodTitle() {
    switch (refundMethod) {
      case RefundMethodType.originalPaymentMethod:
        return 'Original Payment Method';
      case RefundMethodType.cash:
        return 'Cash';
      case RefundMethodType.storeCredit:
        return 'Store Credit';
      case null:
        break;
    }

    final settlement =
        ReturnSettlementMethodOption.findByCode(settlementMethodCode);
    return settlement?.title ?? 'Settlement';
  }

  String _paymentDetail() {
    if (refundMethod == RefundMethodType.originalPaymentMethod ||
        settlementMethodCode == 'CARD_REFUND') {
      return preview.paymentDisplay;
    }
    if (refundMethod == RefundMethodType.cash ||
        settlementMethodCode == 'CASH_REFUND') {
      return 'Cash';
    }
    if (refundMethod == RefundMethodType.storeCredit ||
        settlementMethodCode == 'STORE_CREDIT') {
      return 'Store Credit';
    }
    return preview.paymentDisplay;
  }
}
