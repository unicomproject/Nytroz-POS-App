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
import '../providers/return_create_credit_provider.dart';
import '../providers/return_flow_provider.dart';
import '../widgets/return_continue_footer.dart';
import '../widgets/return_credit_calculation_card.dart';
import '../widgets/return_credit_confirmation_checkbox.dart';
import '../widgets/return_credit_items_summary_card.dart';
import '../widgets/return_credit_preview_card.dart';
import '../widgets/return_credit_reason_card.dart';
import '../widgets/return_credit_sale_summary_panel.dart';
import '../widgets/return_stepper.dart';

class PosReturnCreateCreditScreen extends ConsumerStatefulWidget {
  const PosReturnCreateCreditScreen({super.key});

  @override
  ConsumerState<PosReturnCreateCreditScreen> createState() =>
      _PosReturnCreateCreditScreenState();
}

class _PosReturnCreateCreditScreenState
    extends ConsumerState<PosReturnCreateCreditScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(returnFlowProvider.notifier)
          .setStep(ReturnFlowSteps.createCredit);

      final flowState = ref.read(returnFlowProvider);
      ref.read(returnCreateCreditProvider.notifier).hydrateConfirmation(
            isConfirmed: flowState.creditPreviewConfirmed,
          );
      ref.read(returnCreateCreditProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canCreateRefund(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final flowState = ref.watch(returnFlowProvider);
    final creditState = ref.watch(returnCreateCreditProvider);
    final preview = creditState.preview;
    final hasPrerequisites = flowState.selectedSale != null &&
        flowState.selectedReturnLines.isNotEmpty &&
        flowState.selectedReasonCode != null;

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
                  ReturnStepper(
                    currentStep: ReturnFlowSteps.createCredit,
                    selectedBranch: flowState.selectedResolution,
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  if (!hasPrerequisites)
                    const Expanded(
                      child: TenantAdminEmptyState(
                        title: 'Return flow incomplete',
                        message:
                            'Complete search, item selection, and return reason before creating credit.',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    )
                  else if (creditState.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (creditState.errorMessage != null)
                    Expanded(
                      child: TenantAdminErrorState(
                        title: 'Unable to load credit preview',
                        message: creditState.errorMessage!,
                        onRetry: _isRetryableCreditPreviewError(
                          creditState.errorMessage!,
                        )
                            ? () => ref
                                .read(returnCreateCreditProvider.notifier)
                                .load()
                            : null,
                      ),
                    )
                  else if (preview == null)
                    const Expanded(
                      child: TenantAdminEmptyState(
                        title: 'No credit preview',
                        message: 'Credit preview details are unavailable.',
                        icon: Icons.receipt_long_outlined,
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: useThreeColumns
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _LeftColumn(
                                      preview: preview,
                                      onEditItems: _editItems,
                                    ),
                                  ),
                                  const SizedBox(width: TenantAdminSpacing.lg),
                                  Expanded(
                                    flex: 2,
                                    child: _CenterColumn(
                                      preview: preview,
                                      isConfirmed: creditState.isConfirmed,
                                      showValidation:
                                          creditState.showValidationMessage,
                                      onConfirmationChanged: (value) {
                                        final confirmed = value ?? false;
                                        ref
                                            .read(returnCreateCreditProvider
                                                .notifier)
                                            .setConfirmed(confirmed);
                                        ref
                                            .read(returnFlowProvider.notifier)
                                            .setCreditPreviewConfirmed(
                                                confirmed);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: TenantAdminSpacing.lg),
                                  Expanded(
                                    flex: 2,
                                    child: ReturnCreditSaleSummaryPanel(
                                      preview: preview,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _LeftColumn(
                                    preview: preview,
                                    onEditItems: _editItems,
                                  ),
                                  const SizedBox(height: TenantAdminSpacing.lg),
                                  _CenterColumn(
                                    preview: preview,
                                    isConfirmed: creditState.isConfirmed,
                                    showValidation:
                                        creditState.showValidationMessage,
                                    onConfirmationChanged: (value) {
                                      final confirmed = value ?? false;
                                      ref
                                          .read(returnCreateCreditProvider
                                              .notifier)
                                          .setConfirmed(confirmed);
                                      ref
                                          .read(returnFlowProvider.notifier)
                                          .setCreditPreviewConfirmed(confirmed);
                                    },
                                  ),
                                  const SizedBox(height: TenantAdminSpacing.lg),
                                  ReturnCreditSaleSummaryPanel(
                                      preview: preview),
                                ],
                              ),
                      ),
                    ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  ReturnContinueFooter(
                    canContinue: hasPrerequisites &&
                        preview != null &&
                        creditState.canCreateCredit,
                    cancelLabel: 'Back',
                    continueLabel: 'Create Credit',
                    onCancel: _goBack,
                    onContinue: _createCredit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isRetryableCreditPreviewError(String message) {
    final normalized = message.toLowerCase();
    return !normalized.contains('complete earlier return steps') &&
        !normalized.contains('net credit amount must be greater than zero') &&
        !normalized.contains('completed sale not found');
  }

  void _goBack() {
    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.chooseOption);
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/pos/returns-refunds/choose-option');
  }

  void _editItems() {
    context.go('/pos/returns-refunds/eligibility');
  }

  void _createCredit() {
    if (!ref.read(returnCreateCreditProvider.notifier).validateConfirmation()) {
      return;
    }

    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.settlement);
    context.push('/pos/returns-refunds/settlement');
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({
    required this.preview,
    required this.onEditItems,
  });

  final ReturnCreditPreview preview;
  final VoidCallback onEditItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReturnCreditItemsSummaryCard(
          items: preview.items,
          currency: preview.currency,
          onEditItems: onEditItems,
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        ReturnCreditReasonCard(reasonLabel: preview.reasonLabel),
        const SizedBox(height: TenantAdminSpacing.lg),
        ReturnCreditCalculationCard(
          currency: preview.currency,
          calculation: preview.calculation,
        ),
      ],
    );
  }
}

class _CenterColumn extends StatelessWidget {
  const _CenterColumn({
    required this.preview,
    required this.isConfirmed,
    required this.showValidation,
    required this.onConfirmationChanged,
  });

  final ReturnCreditPreview preview;
  final bool isConfirmed;
  final bool showValidation;
  final ValueChanged<bool?> onConfirmationChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReturnCreditPreviewCard(preview: preview),
        const SizedBox(height: TenantAdminSpacing.lg),
        ReturnCreditConfirmationCheckbox(
          value: isConfirmed,
          onChanged: onConfirmationChanged,
          showValidationMessage: showValidation,
        ),
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
          tooltip: 'Back to Return Reason',
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
                'Create Customer Credit',
                style: TenantAdminTextStyles.pageTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                'Review the return value and generate customer credit.',
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
