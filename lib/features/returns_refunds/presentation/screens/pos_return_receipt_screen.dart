import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../providers/return_flow_provider.dart';
import '../providers/return_receipt_provider.dart';
import '../widgets/return_completed_success_banner.dart';
import '../widgets/return_receipt_actions_card.dart';
import '../widgets/return_receipt_audit_card.dart';
import '../widgets/return_receipt_preview_card.dart';
import '../widgets/return_receipt_summary_panel.dart';
import '../widgets/return_stepper.dart';

class PosReturnReceiptScreen extends ConsumerStatefulWidget {
  const PosReturnReceiptScreen({super.key});

  @override
  ConsumerState<PosReturnReceiptScreen> createState() =>
      _PosReturnReceiptScreenState();
}

class _PosReturnReceiptScreenState extends ConsumerState<PosReturnReceiptScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.receipt);
      ref.read(returnReceiptProvider.notifier).completeReturnIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canViewReturnsOrRefunds(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final flowState = ref.watch(returnFlowProvider);
    final receiptState = ref.watch(returnReceiptProvider);
    final receipt = receiptState.receipt;

    final hasPrerequisites = flowState.selectedSale != null &&
        flowState.selectedReturnLines.isNotEmpty &&
        flowState.selectedReasonCode != null &&
        flowState.creditPreviewConfirmed &&
        flowState.selectedSettlementMethodCode != null;

    return ColoredBox(
      color: TenantAdminColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);
          final useThreeColumns = constraints.maxWidth >= 1200;

          return Padding(
            padding: padding,
            child: SizedBox.expand(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(onBack: _goBack),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  const ReturnStepper(currentStep: ReturnFlowSteps.receipt),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  if (!hasPrerequisites)
                    const Expanded(
                      child: TenantAdminEmptyState(
                        title: 'Return flow incomplete',
                        message:
                            'Complete settlement before viewing the receipt.',
                        icon: Icons.receipt_long_outlined,
                      ),
                    )
                  else if (receiptState.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (receiptState.errorMessage != null)
                    Expanded(
                      child: TenantAdminErrorState(
                        title: 'Unable to complete return',
                        message: receiptState.errorMessage!,
                        onRetry: () => ref
                            .read(returnReceiptProvider.notifier)
                            .completeReturnIfNeeded(),
                      ),
                    )
                  else if (receipt == null)
                    const Expanded(
                      child: TenantAdminEmptyState(
                        title: 'No receipt data',
                        message: 'Return receipt details are unavailable.',
                        icon: Icons.receipt_long_outlined,
                      ),
                    )
                  else ...[
                    const ReturnCompletedSuccessBanner(),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            useThreeColumns
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: ReturnReceiptPreviewCard(
                                          receipt: receipt,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: TenantAdminSpacing.lg,
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: ReturnReceiptActionsCard(
                                          onPrintReceipt: () =>
                                              _printReceipt(context),
                                          onNewReturn: _startNewReturn,
                                          onBackToDashboard:
                                              _backToDashboard,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: TenantAdminSpacing.lg,
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: ReturnReceiptSummaryPanel(
                                          receipt: receipt,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ReturnReceiptPreviewCard(
                                        receipt: receipt,
                                      ),
                                      const SizedBox(
                                        height: TenantAdminSpacing.lg,
                                      ),
                                      ReturnReceiptActionsCard(
                                        onPrintReceipt: () =>
                                            _printReceipt(context),
                                        onNewReturn: _startNewReturn,
                                        onBackToDashboard: _backToDashboard,
                                      ),
                                      const SizedBox(
                                        height: TenantAdminSpacing.lg,
                                      ),
                                      ReturnReceiptSummaryPanel(
                                        receipt: receipt,
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: TenantAdminSpacing.lg),
                            ReturnReceiptAuditCard(receipt: receipt),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/pos/returns-refunds/settlement');
  }

  void _printReceipt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Return receipt printing will be available soon.'),
      ),
    );
  }

  void _startNewReturn() {
    ref.read(returnFlowProvider.notifier).reset();
    context.go('/pos/returns-refunds');
  }

  void _backToDashboard() {
    ref.read(returnFlowProvider.notifier).reset();
    context.go('/pos/home');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onBack,
          tooltip: 'Back to Settlement',
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: TenantAdminColors.surface,
            side: const BorderSide(color: TenantAdminColors.border),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Return Completed',
                style: TenantAdminTextStyles.pageTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                'The return has been processed successfully.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TenantAdminColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
