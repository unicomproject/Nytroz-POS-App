import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../shared/widgets/pos_action_buttons.dart';

class SuccessPageActions extends StatelessWidget {
  const SuccessPageActions({
    super.key,
    required this.onPrintReceipt,
    required this.onStartNewReturn,
    required this.onBackToHome,
    this.onRetryAudit,
    this.isPrinting = false,
    this.isNavigating = false,
    this.printEnabled = true,
    this.startNewReturnEnabled = true,
    this.backToHomeEnabled = true,
    this.hasBeenPrinted = false,
    this.auditPending = false,
  });

  final VoidCallback onPrintReceipt;
  final VoidCallback onStartNewReturn;
  final VoidCallback onBackToHome;
  final VoidCallback? onRetryAudit;
  final bool isPrinting;
  final bool isNavigating;
  final bool printEnabled;
  final bool startNewReturnEnabled;
  final bool backToHomeEnabled;
  final bool hasBeenPrinted;
  final bool auditPending;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wrap = constraints.maxWidth < 760;
        final showPrint = printEnabled || isPrinting || auditPending;

        final printLabel = auditPending
            ? 'Retry Print Audit'
            : (hasBeenPrinted ? 'Reprint Receipt' : 'Print Receipt');

        final printButton = OutlinedButton.icon(
          onPressed: printEnabled && !isPrinting && !isNavigating
              ? (auditPending ? (onRetryAudit ?? onPrintReceipt) : onPrintReceipt)
              : null,
          icon: isPrinting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  auditPending
                      ? Icons.cloud_upload_outlined
                      : Icons.print_outlined,
                  size: 18,
                ),
          label: Text(printLabel),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: TenantAdminColors.primary,
            side: const BorderSide(color: TenantAdminColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
          ),
        );

        final newReturnButton = OutlinedButton.icon(
          onPressed: startNewReturnEnabled && !isNavigating
              ? onStartNewReturn
              : null,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Start New Return'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: TenantAdminColors.primary,
            side: const BorderSide(color: TenantAdminColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
          ),
        );

        final homeButton = PosPrimaryActionButton(
          label: 'Back to POS Home',
          onPressed:
              backToHomeEnabled && !isNavigating ? onBackToHome : null,
          leadingIcon: Icons.home_outlined,
          isLoading: isNavigating,
          compact: true,
          borderRadius: TenantAdminRadius.sm,
        );

        if (wrap) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showPrint) ...[
                printButton,
                const SizedBox(height: TenantAdminSpacing.md),
              ],
              newReturnButton,
              const SizedBox(height: TenantAdminSpacing.md),
              homeButton,
            ],
          );
        }

        return Row(
          children: [
            if (showPrint) ...[
              Expanded(child: printButton),
              const SizedBox(width: TenantAdminSpacing.md),
            ],
            Expanded(child: newReturnButton),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(child: homeButton),
          ],
        );
      },
    );
  }
}
