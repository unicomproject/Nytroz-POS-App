import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../../domain/entities/return_settlement_method.dart';
import '../providers/return_flow_provider.dart';
import '../providers/return_settlement_provider.dart';
import '../widgets/return_continue_footer.dart';
import '../widgets/return_settlement_methods_section.dart';
import '../widgets/return_settlement_preview_card.dart';
import '../widgets/return_settlement_summary_panel.dart';
import '../widgets/return_settlement_validation_message.dart';
import '../widgets/return_stepper.dart';

class PosReturnSettlementScreen extends ConsumerStatefulWidget {
  const PosReturnSettlementScreen({super.key});

  @override
  ConsumerState<PosReturnSettlementScreen> createState() =>
      _PosReturnSettlementScreenState();
}

class _PosReturnSettlementScreenState
    extends ConsumerState<PosReturnSettlementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.settlement);
      ref.read(returnSettlementProvider.notifier).load();
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
    final settlementState = ref.watch(returnSettlementProvider);
    final preview = settlementState.preview;
    final settlementValues = settlementState.settlementPreview;

    final hasPrerequisites = flowState.selectedSale != null &&
        flowState.selectedReturnLines.isNotEmpty &&
        flowState.selectedReasonCode != null &&
        flowState.creditPreviewConfirmed;

    final showValidation = settlementState.showValidationMessage ||
        settlementState.selectedMethodCode == null;

    return ColoredBox(
      color: TenantAdminColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);
          final useSidePanel = constraints.maxWidth >= 1200;

          return Padding(
            padding: padding,
            child: SizedBox.expand(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(onBack: _goBack),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  const ReturnStepper(currentStep: ReturnFlowSteps.settlement),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  if (!hasPrerequisites)
                    const Expanded(
                      child: TenantAdminEmptyState(
                        title: 'Return flow incomplete',
                        message:
                            'Complete credit confirmation before choosing settlement.',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    )
                  else if (settlementState.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (settlementState.errorMessage != null)
                    Expanded(
                      child: TenantAdminErrorState(
                        title: 'Unable to load settlement',
                        message: settlementState.errorMessage!,
                        onRetry: () =>
                            ref.read(returnSettlementProvider.notifier).load(),
                      ),
                    )
                  else if (preview == null)
                    const Expanded(
                      child: TenantAdminEmptyState(
                        title: 'No settlement data',
                        message: 'Settlement preview details are unavailable.',
                        icon: Icons.payments_outlined,
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: useSidePanel
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _MainColumn(
                                      preview: preview,
                                      settlementValues: settlementValues,
                                      selectedMethodCode:
                                          settlementState.selectedMethodCode,
                                      onMethodSelected: ref
                                          .read(returnSettlementProvider
                                              .notifier)
                                          .selectMethod,
                                    ),
                                  ),
                                  const SizedBox(width: TenantAdminSpacing.lg),
                                  Expanded(
                                    flex: 2,
                                    child: ReturnSettlementSummaryPanel(
                                      preview: preview,
                                      settlementValues: settlementValues,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _MainColumn(
                                    preview: preview,
                                    settlementValues: settlementValues,
                                    selectedMethodCode:
                                        settlementState.selectedMethodCode,
                                    onMethodSelected: ref
                                        .read(returnSettlementProvider.notifier)
                                        .selectMethod,
                                  ),
                                  const SizedBox(height: TenantAdminSpacing.lg),
                                  ReturnSettlementSummaryPanel(
                                    preview: preview,
                                    settlementValues: settlementValues,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  if (hasPrerequisites &&
                      preview != null &&
                      showValidation &&
                      settlementState.selectedMethodCode == null)
                    const ReturnSettlementValidationMessage(),
                  if (hasPrerequisites &&
                      preview != null &&
                      showValidation &&
                      settlementState.selectedMethodCode == null)
                    const SizedBox(height: TenantAdminSpacing.md),
                  ReturnContinueFooter(
                    canContinue: hasPrerequisites &&
                        preview != null &&
                        settlementState.canConfirmSettlement,
                    cancelLabel: 'Back',
                    continueLabel: 'Confirm Settlement',
                    onCancel: _goBack,
                    onContinue: _confirmSettlement,
                  ),
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
    context.go('/pos/returns-refunds/create-credit');
  }

  void _confirmSettlement() {
    if (!ref.read(returnSettlementProvider.notifier).validateSelection()) {
      return;
    }

    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.receipt);
    context.push('/pos/returns-refunds/receipt');
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({
    required this.preview,
    required this.settlementValues,
    required this.selectedMethodCode,
    required this.onMethodSelected,
  });

  final ReturnCreditPreview preview;
  final ReturnSettlementPreviewValues? settlementValues;
  final String? selectedMethodCode;
  final ValueChanged<String> onMethodSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReturnSettlementMethodsSection(
          preview: preview,
          selectedMethodCode: selectedMethodCode,
          onMethodSelected: onMethodSelected,
        ),
        if (settlementValues != null) ...[
          const SizedBox(height: TenantAdminSpacing.xl),
          ReturnSettlementPreviewCard(
            preview: preview,
            values: settlementValues!,
          ),
        ],
      ],
    );
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
          tooltip: 'Back to Create Credit',
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
                'Choose Settlement Method',
                style: TenantAdminTextStyles.pageTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                'Select how the customer credit should be settled.',
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
