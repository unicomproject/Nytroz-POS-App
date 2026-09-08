import 'package:flutter/material.dart';

import '../../../../../shared/pos_session/pos_session_context.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_cash_payment_success_provider.dart';
import '../receipt/thermal_receipt_preview.dart';
import 'actions/payment_success_actions.dart';
import 'summary/payment_success_detail_list.dart';
import 'summary/payment_success_status_header.dart';

class PaymentSuccessScreenBody extends StatelessWidget {
  const PaymentSuccessScreenBody({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final useWideLayout =
            constraints.maxWidth >= TenantAdminBreakpoints.tablet;
        final contentWidth = constraints.maxWidth.clamp(0.0, 1200.0);

        return Center(
          child: SizedBox(
            width: contentWidth,
            height: constraints.maxHeight,
            child: useWideLayout
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          successData: successData,
                          cashierName: cashierName,
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(
                        child: _ReceiptCard(
                          successData: successData,
                          cashierName: cashierName,
                          sessionContext: sessionContext,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          successData: successData,
                          cashierName: cashierName,
                        ),
                      ),
                      const SizedBox(height: TenantAdminSpacing.md),
                      Expanded(
                        child: _ReceiptCard(
                          successData: successData,
                          cashierName: cashierName,
                          sessionContext: sessionContext,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.successData,
    required this.cashierName,
  });

  final PosCashPaymentSuccessData successData;
  final String cashierName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('payment-success-summary-card'),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 540,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PaymentSuccessStatusHeader(),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  PaymentSuccessDetailList(
                    successData: successData,
                    cashierName: cashierName,
                  ),
                  const SizedBox(height: TenantAdminSpacing.xl * 1.5),
                  PaymentSuccessActions(saleId: successData.saleId),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.successData,
    required this.cashierName,
    required this.sessionContext,
  });

  final PosCashPaymentSuccessData successData;
  final String cashierName;
  final PosSessionContext sessionContext;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('payment-success-receipt-card'),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        child: Scrollbar(
          child: SingleChildScrollView(
            key: const Key('payment-success-receipt-scroll'),
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: ThermalReceiptPreview.fromPaymentSuccess(
              successData: successData,
              cashierName: cashierName,
              sessionContext: sessionContext,
            ),
          ),
        ),
      ),
    );
  }
}
