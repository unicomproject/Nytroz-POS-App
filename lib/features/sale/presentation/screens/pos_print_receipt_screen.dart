import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../shared/pos_session/pos_session_provider.dart';
import '../providers/pos_cash_payment_success_provider.dart';
import '../providers/pos_checkout_summary_provider.dart';
import '../widgets/print_receipt/print_receipt_bottom_actions.dart';
import '../widgets/print_receipt/print_receipt_header.dart';
import '../widgets/print_receipt/printer_options_card.dart';
import '../widgets/print_receipt/receipt_preview_card.dart';

class PosPrintReceiptScreen extends ConsumerWidget {
  const PosPrintReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final successData = ref.watch(posCashPaymentSuccessProvider);
    final sessionContext = ref.watch(posSessionContextProvider);

    if (!PosPermissionAccess.canPrintReceiptsSession(session)) {
      return const TenantAdminForbiddenScreen();
    }

    if (successData == null) {
      return _MissingReceiptFallback(
        onBack: () => context.go('/pos/new-sale'),
      );
    }

    final cashierName = session?.userDisplayName.trim().isNotEmpty == true
        ? session!.userDisplayName
        : sessionContext.userName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);
        final useWideLayout =
            constraints.maxWidth >= TenantAdminBreakpoints.tablet;

        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrintReceiptHeader(
                onBack: () => context.pop(),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              Expanded(
                child: useWideLayout
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                              child: ReceiptPreviewCard(
                                successData: successData,
                                cashierName: cashierName,
                                sessionContext: sessionContext,
                              ),
                            ),
                          ),
                          const SizedBox(width: TenantAdminSpacing.lg),
                          const Expanded(
                            flex: 2,
                            child: SingleChildScrollView(
                              child: PrinterOptionsCard(),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ReceiptPreviewCard(
                              successData: successData,
                              cashierName: cashierName,
                              sessionContext: sessionContext,
                            ),
                            const SizedBox(height: TenantAdminSpacing.lg),
                            const PrinterOptionsCard(),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              PrintReceiptBottomActions(
                onBack: () => context.pop(),
                onPrintReceipt: () => _recordPrintAndShowMessage(
                  context,
                  ref,
                  successData.saleId,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _recordPrintAndShowMessage(
    BuildContext context,
    WidgetRef ref,
    String saleId,
  ) async {
    if (saleId.isNotEmpty) {
      try {
        await ref
            .read(posCheckoutRemoteDatasourceProvider)
            .recordReceiptPrint(saleId: saleId);
      } catch (_) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Receipt print audit could not be recorded.'),
            ),
          );
        return;
      }
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Print receipt is not implemented yet.')),
      );
  }
}

class _MissingReceiptFallback extends StatelessWidget {
  const _MissingReceiptFallback({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.print_outlined,
            size: 48,
            color: TenantAdminColors.mutedText,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
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
          const SizedBox(height: TenantAdminSpacing.lg),
          FilledButton(
            onPressed: onBack,
            child: const Text('Back to New Sale'),
          ),
        ],
      ),
    );
  }
}
