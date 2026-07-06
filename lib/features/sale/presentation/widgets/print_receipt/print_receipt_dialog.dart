import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/pos_session/pos_session_provider.dart';
import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_cash_payment_success_provider.dart';
import '../payment/pos_bottom_action_buttons.dart';
import '../receipt/thermal_receipt_preview.dart';
import 'print_receipt_actions.dart';

/// Opens the receipt preview + print action as a modal on the Payment Success
/// screen (no route navigation).
Future<void> showPrintReceiptDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const PrintReceiptDialog(),
  );
}

class PrintReceiptDialog extends ConsumerStatefulWidget {
  const PrintReceiptDialog({super.key});

  @override
  ConsumerState<PrintReceiptDialog> createState() => _PrintReceiptDialogState();
}

class _PrintReceiptDialogState extends ConsumerState<PrintReceiptDialog> {
  bool _printing = false;

  @override
  Widget build(BuildContext context) {
    final successData = ref.watch(posCashPaymentSuccessProvider);
    final session = ref.watch(authSessionProvider);
    final sessionContext = ref.watch(posSessionContextProvider);

    if (successData == null) {
      return _buildShell(
        context,
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Receipt preview unavailable',
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              Text(
                'Complete a cash payment to preview and print the receipt.',
                textAlign: TextAlign.center,
                style: TenantAdminTextStyles.muted(context),
              ),
            ],
          ),
        ),
      );
    }

    final cashierName = session?.userDisplayName.trim().isNotEmpty == true
        ? session!.userDisplayName
        : sessionContext.userName;

    return _buildShell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
              color: TenantAdminColors.mutedText,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.md,
              ),
              child: ThermalReceiptPreview(
                successData: successData,
                cashierName: cashierName,
                sessionContext: sessionContext,
              ),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Padding(
            padding: EdgeInsets.fromLTRB(
              TenantAdminSpacing.md,
              0,
              TenantAdminSpacing.md,
              TenantAdminSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: PosBottomFilledButton(
              label: 'Print Receipt',
              icon: Icons.print_outlined,
              isLoading: _printing,
              onPressed: _printing ? null : () => _onPrint(successData.saleId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShell(BuildContext context, {required Widget child}) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < TenantAdminBreakpoints.mobile;

    if (isMobile) {
      return Dialog.fullscreen(
        backgroundColor: TenantAdminColors.surface,
        child: SafeArea(child: child),
      );
    }

    return Dialog(
      backgroundColor: TenantAdminColors.surface,
      insetPadding: const EdgeInsets.all(TenantAdminSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: size.height * 0.85,
        ),
        child: SafeArea(child: child),
      ),
    );
  }

  Future<void> _onPrint(String saleId) async {
    setState(() => _printing = true);
    await executeReceiptPrint(context, ref, saleId);
    if (!mounted) {
      return;
    }
    setState(() => _printing = false);
  }
}
