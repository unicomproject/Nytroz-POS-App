import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';

import '../../../../shared/pos_session/pos_session_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/pos_cash_payment_success_provider.dart';
import '../utils/receipt_cashier_display.dart';
import '../widgets/payment_success/payment_success_screen_body.dart';

class PosPaymentSuccessScreen extends ConsumerWidget {
  const PosPaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final successData = ref.watch(posCashPaymentSuccessProvider);
    final sessionContext = ref.watch(posSessionContextProvider);

    if (!PosPermissionAccess.canViewPaymentSuccessSession(session)) {
      return const TenantAdminForbiddenScreen();
    }

    if (successData == null) {
      return _MissingSuccessFallback(
        onBack: () => context.go('/pos/new-sale'),
      );
    }

    final cashierName = resolveReceiptCashierDisplayName(
      receiptDataJson: successData.receiptDataJson,
      paymentCashierName: successData.cashierName,
      sessionDisplayName: session?.userDisplayName,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);

        return Padding(
          padding: padding,
          child: PaymentSuccessScreenBody(
            successData: successData,
            cashierName: cashierName,
            sessionContext: sessionContext,
          ),
        );
      },
    );
  }
}

class _MissingSuccessFallback extends StatelessWidget {
  const _MissingSuccessFallback({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: TenantAdminColors.warning,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            const Text(
              'No completed sale data found.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TenantAdminColors.bodyText,
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              'Please return to New Sale to start a new transaction.',
              style: TextStyle(
                fontSize: 14,
                color: TenantAdminColors.bodyText.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.xl),
            ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: TenantAdminColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: TenantAdminSpacing.xl,
                  vertical: TenantAdminSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
              child: const Text('Return to New Sale'),
            ),
          ],
        ),
      ),
    );
  }
}
