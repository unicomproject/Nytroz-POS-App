import 'package:flutter/material.dart';

import '../../../../../shared/pos_session/pos_session_context.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_cash_payment_success_provider.dart';
import '../payment/payment_panel_card.dart';
import '../receipt/thermal_receipt_preview.dart';

class ReceiptPreviewCard extends StatelessWidget {
  const ReceiptPreviewCard({
    super.key,
    required this.successData,
    required this.cashierName,
    required this.sessionContext,
  });

  final PosCashPaymentSuccessData successData;
  final String cashierName;
  final PosSessionContext sessionContext;

  @override
  Widget build(BuildContext context) {
    return PaymentPanelCard(
      title: 'RECEIPT PREVIEW',
      icon: Icons.receipt_long_outlined,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TenantAdminColors.background,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          child: ThermalReceiptPreview(
            successData: successData,
            cashierName: cashierName,
            sessionContext: sessionContext,
          ),
        ),
      ),
    );
  }
}
