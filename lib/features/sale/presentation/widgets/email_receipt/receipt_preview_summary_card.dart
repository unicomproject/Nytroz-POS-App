import 'package:flutter/material.dart';

import '../../../../../shared/pos_session/pos_session_context.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_cash_payment_success_provider.dart';
import '../payment/payment_panel_card.dart';
import '../receipt/thermal_receipt_preview.dart';

class ReceiptPreviewSummaryCard extends StatelessWidget {
  const ReceiptPreviewSummaryCard({
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
      title: 'Receipt Preview',
      icon: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This is the receipt format that will be sent.',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          DecoratedBox(
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
        ],
      ),
    );
  }
}
