import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../domain/entities/pos_receipt_snapshot.dart';
import '../../../providers/pos_cash_payment_success_provider.dart';

class PaymentSuccessDetailList extends StatelessWidget {
  const PaymentSuccessDetailList({
    super.key,
    required this.successData,
    required this.cashierName,
  });

  final PosCashPaymentSuccessData successData;
  final String cashierName;

  @override
  Widget build(BuildContext context) {
    final snapshot = PosReceiptSnapshot.parse(successData.receiptDataJson);

    final String paymentMethodLabel;
    final List<Widget> tenderRows = [];

    if (snapshot != null && snapshot.tenders.isNotEmpty) {
      if (snapshot.tenders.length == 1) {
        final tender = snapshot.tenders.first;
        paymentMethodLabel = tender.paymentMethod;
        if (tender.paymentMethod.toLowerCase() == 'cash') {
          tenderRows.add(_DetailRow(
            icon: Icons.payments_outlined,
            label: 'Cash Received',
            value: _formatCurrency(successData.cashReceived),
          ));
          tenderRows.add(_DetailRow(
            icon: Icons.change_circle_outlined,
            label: 'Change Due',
            value: _formatCurrency(successData.changeDue),
          ));
        } else {
          if (tender.safeReference != null &&
              tender.safeReference!.isNotEmpty) {
            tenderRows.add(_DetailRow(
              icon: Icons.credit_card_outlined,
              label: 'Reference',
              value: tender.safeReference!,
            ));
          }
        }
      } else {
        paymentMethodLabel = 'Split Payment';
        for (final tender in snapshot.tenders) {
          tenderRows.add(_DetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: tender.paymentMethod,
            value: _formatCurrency(tender.amount),
          ));
        }
        if (successData.changeDue > 0) {
          tenderRows.add(_DetailRow(
            icon: Icons.change_circle_outlined,
            label: 'Change Due',
            value: _formatCurrency(successData.changeDue),
          ));
        }
      }
    } else {
      paymentMethodLabel = 'Cash'; // Fallback to local state if missing
      tenderRows.add(_DetailRow(
        icon: Icons.payments_outlined,
        label: 'Cash Received',
        value: _formatCurrency(successData.cashReceived),
      ));
      tenderRows.add(_DetailRow(
        icon: Icons.change_circle_outlined,
        label: 'Change Due',
        value: _formatCurrency(successData.changeDue),
      ));
    }

    return Column(
      children: [
        _DetailRow(
          icon: Icons.receipt_long_outlined,
          label: 'Receipt No.',
          value: successData.receiptNumber,
        ),
        _DetailRow(
          icon: Icons.payment_outlined,
          label: 'Payment Method',
          value: paymentMethodLabel,
        ),
        _DetailRow(
          icon: Icons.access_time_rounded,
          label: 'Date & Time',
          value: _formatDateTime(successData.completedAt),
        ),
        _DetailRow(
          icon: Icons.person_outline,
          label: 'Cashier',
          value: snapshot?.operatorDetails.cashierName ?? cashierName,
        ),
        ...tenderRows,
        _DetailRow(
          icon: Icons.attach_money_rounded,
          label: 'Total Paid',
          value: _formatCurrency(successData.total),
          isTotal: true,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  String _formatCurrency(int amount) => formatLkr(amount);
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: TenantAdminColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TenantAdminSpacing.sm),
            decoration: BoxDecoration(
              color: isTotal
                  ? TenantAdminColors.success.withValues(alpha: 0.1)
                  : TenantAdminColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isTotal
                  ? TenantAdminColors.success
                  : TenantAdminColors.bodyText.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal
                  ? TenantAdminColors.success
                  : TenantAdminColors.bodyText.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal
                  ? TenantAdminColors.success
                  : TenantAdminColors.bodyText,
            ),
          ),
        ],
      ),
    );
  }
}
