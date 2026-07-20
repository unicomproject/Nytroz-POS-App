import 'package:flutter/material.dart';
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_states.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../navigation/returns_route_guard.dart';
import '../providers/return_eligibility_provider.dart';
import '../providers/return_flow_provider.dart';
import '../providers/return_reason_provider.dart';
import '../widgets/return_stepper.dart';
import '../widgets/return_reason/return_exchange_reason_card.dart';
import '../widgets/return_reason/return_policy_information_banner.dart';
import '../widgets/return_reason/return_reason_header.dart';
import '../widgets/return_reason/per_line_return_reason_list.dart';
import '../widgets/return_reason/selected_return_items_card.dart';

class PosReturnReasonScreen extends ConsumerStatefulWidget {
  const PosReturnReasonScreen({super.key});

  @override
  ConsumerState<PosReturnReasonScreen> createState() =>
      _PosReturnReasonScreenState();
}

class _PosReturnReasonScreenState extends ConsumerState<PosReturnReasonScreen> {
  late final TextEditingController _notesController;
  var _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeReasonState();
    });
  }

  Future<void> _initializeReasonState() async {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canViewReturns(granted) ||
        !PosPermissionAccess.canCreateReturn(granted)) {
      return;
    }

    final flowState = ref.read(returnFlowProvider);
    final eligibilityState = ref.read(returnEligibilityProvider);
    if (!ReturnsRouteGuard.hasReturnReasonContext(
      flow: flowState,
      eligibility: eligibilityState,
    )) {
      _redirectToLatestValidStep(eligibilityState);
      return;
    }

    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.returnReason);

    final saleLineIds = [
      for (final line in flowState.selectedReturnLines) line.saleLineId,
    ];

    if (saleLineIds.isEmpty) {
      return;
    }

    await ref.read(returnReasonProvider.notifier).load(
          saleLineIds: saleLineIds,
          selectedReasonCode: flowState.selectedReasonCode,
          notes: flowState.returnNotes,
          applySameReasonToAll: flowState.applySameReasonToAll,
          existingSelections: flowState.lineReasonSelections.isEmpty
              ? null
              : flowState.lineReasonSelections,
        );

    if (!mounted) {
      return;
    }

    _notesController.text = ref.read(returnReasonProvider).notes;
  }

  void _redirectToLatestValidStep(ReturnEligibilityState eligibility) {
    if (_redirectScheduled || !mounted) {
      return;
    }
    _redirectScheduled = true;

    final flow = ref.read(returnFlowProvider);
    if (ReturnsRouteGuard.hasCheckEligibilityContext(flow) &&
        PosPermissionAccess.canViewReturns(
          ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {},
        )) {
      context.go('/pos/returns-refunds/check-eligibility');
      return;
    }

    context.go('/pos/returns-refunds/eligibility');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canViewReturns(granted) ||
        !PosPermissionAccess.canCreateReturn(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final flowState = ref.watch(returnFlowProvider);
    final eligibilityState = ref.watch(returnEligibilityProvider);
    final reasonState = ref.watch(returnReasonProvider);

    if (reasonState.permissionDenied) {
      return const TenantAdminForbiddenScreen();
    }

    if (!ReturnsRouteGuard.hasReturnReasonContext(
      flow: flowState,
      eligibility: eligibilityState,
    )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectToLatestValidStep(eligibilityState);
      });
      return const ColoredBox(
        color: TenantAdminColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final selectedLines = flowState.selectedReturnLines;
    final currency = flowState.selectedSale?.currency ?? '';
    final policyNote = eligibilityState.checkResult?.policyNote?.trim();
    final canContinue = ReturnsRouteGuard.canContinueFromReturnReason(
      granted: granted,
      flow: flowState,
      eligibility: eligibilityState,
      reasonCanContinue: reasonState.canContinue,
      isSaving: reasonState.isSaving,
    );

    return ColoredBox(
      color: TenantAdminColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth >= TenantAdminBreakpoints.tablet
              ? const EdgeInsets.fromLTRB(22, 20, 22, 22)
              : TenantAdminInsets.pageForWidth(constraints.maxWidth);

          return Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: _TopStatus(),
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                const ReturnStepper(currentStep: ReturnFlowSteps.returnReason),
                const SizedBox(height: TenantAdminSpacing.xl),
                Expanded(
                  child: _Body(
                    selectedSaleMissing: flowState.selectedSale == null,
                    selectedLines: selectedLines,
                    currency: currency,
                    reasonState: reasonState,
                    canContinue: canContinue,
                    policyNote: policyNote,
                    notesController: _notesController,
                    onRetry: _initializeReasonState,
                    onBack: _goBack,
                    onContinue: _continueToInspectItems,
                    onReasonSelected:
                        ref.read(returnReasonProvider.notifier).selectReason,
                    onNotesChanged:
                        ref.read(returnReasonProvider.notifier).setNotes,
                    onApplySameReasonChanged: ref
                        .read(returnReasonProvider.notifier)
                        .setApplySameReasonToAll,
                    onLineReasonSelected: (saleLineId, code) {
                      ref.read(returnReasonProvider.notifier).selectLineReason(
                            saleLineId: saleLineId,
                            code: code,
                          );
                    },
                    onLineNotesChanged: (saleLineId, notes) {
                      ref.read(returnReasonProvider.notifier).setLineNotes(
                            saleLineId: saleLineId,
                            value: notes,
                          );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _goBack() {
    final reasonState = ref.read(returnReasonProvider);
    final reasonCode = reasonState.selectedReasonCode;
    if (reasonCode != null && reasonCode.isNotEmpty) {
      ref.read(returnFlowProvider.notifier).setReturnReason(
            reasonCode: reasonCode,
            notes: reasonState.notes,
            applySameReasonToAll: reasonState.applySameReasonToAll,
            lineSelections: reasonState.lineSelections,
          );
    }

    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/pos/returns-refunds/check-eligibility');
  }

  void _continueToInspectItems() async {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    final flowState = ref.read(returnFlowProvider);
    final eligibilityState = ref.read(returnEligibilityProvider);
    final reasonState = ref.read(returnReasonProvider);

    if (!ReturnsRouteGuard.canContinueFromReturnReason(
      granted: granted,
      flow: flowState,
      eligibility: eligibilityState,
      reasonCanContinue: reasonState.canContinue,
      isSaving: reasonState.isSaving,
    )) {
      if (!PosPermissionAccess.canCreateReturn(granted)) {
        PosPermissionAccess.showAccessDeniedSnackBar(
          context,
          'You do not have permission to continue this return.',
        );
      } else {
        ref.read(returnReasonProvider.notifier).validate();
      }
      return;
    }

    final saleId = flowState.selectedSale?.saleId;
    if (saleId == null || saleId.isEmpty) {
      return;
    }

    final saved = await ref
        .read(returnReasonProvider.notifier)
        .saveValidatedReasons(saleId: saleId);
    if (!saved || !mounted) {
      return;
    }

    final updatedReason = ref.read(returnReasonProvider);
    final reasonCode = updatedReason.applySameReasonToAll
        ? updatedReason.selectedReasonCode
        : updatedReason.lineSelections.values
            .map((selection) => selection.reasonCode)
            .firstWhere(
              (code) => code.isNotEmpty,
              orElse: () => '',
            );
    if (reasonCode == null || reasonCode.isEmpty) {
      return;
    }

    final step4Inspection =
        eligibilityState.checkResult?.requiresInspection == true;
    final step4Approval =
        eligibilityState.checkResult?.requiresManagerApproval == true;

    ref.read(returnFlowProvider.notifier)
      ..setReturnReason(
        reasonCode: reasonCode,
        notes: updatedReason.applySameReasonToAll
            ? updatedReason.notes
            : updatedReason.lineSelections.values
                .map((selection) => selection.notes)
                .firstWhere(
                  (notes) => notes.trim().isNotEmpty,
                  orElse: () => '',
                ),
        applySameReasonToAll: updatedReason.applySameReasonToAll,
        lineSelections: updatedReason.lineSelections,
        reasonsValidated: true,
        requiresInspection:
            step4Inspection || updatedReason.anyRequiresInspection,
        requiresManagerApproval:
            step4Approval || updatedReason.anyRequiresManagerApproval,
      )
      ..setStep(ReturnFlowSteps.inspectItems);

    context.push('/pos/returns-refunds/inspect-items');
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.selectedSaleMissing,
    required this.selectedLines,
    required this.currency,
    required this.reasonState,
    required this.canContinue,
    required this.policyNote,
    required this.notesController,
    required this.onRetry,
    required this.onBack,
    required this.onContinue,
    required this.onReasonSelected,
    required this.onNotesChanged,
    required this.onApplySameReasonChanged,
    required this.onLineReasonSelected,
    required this.onLineNotesChanged,
  });

  final bool selectedSaleMissing;
  final List<ReturnSelectedReturnLine> selectedLines;
  final String currency;
  final ReturnReasonState reasonState;
  final bool canContinue;
  final String? policyNote;
  final TextEditingController notesController;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final ValueChanged<String> onReasonSelected;
  final ValueChanged<String> onNotesChanged;
  final ValueChanged<bool> onApplySameReasonChanged;
  final void Function(String saleLineId, String reasonCode) onLineReasonSelected;
  final void Function(String saleLineId, String notes) onLineNotesChanged;

  @override
  Widget build(BuildContext context) {
    if (selectedSaleMissing || selectedLines.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            child: TenantAdminEmptyState(
              title: 'No items selected',
              message:
                  'Go back and select return items before choosing a reason.',
              icon: Icons.assignment_return_outlined,
            ),
          ),
          _ActionFooter(
            canContinue: false,
            onBack: onBack,
            onContinue: onContinue,
          ),
        ],
      );
    }

    if (reasonState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reasonState.errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TenantAdminErrorState(
              title: 'Unable to load return reasons',
              message: reasonState.errorMessage!,
              onRetry: onRetry,
            ),
          ),
          _ActionFooter(
            canContinue: false,
            onBack: onBack,
            onContinue: onContinue,
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 960;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ReturnReasonHeader(),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    if (reasonState.applySameReasonToAll) ...[
                      if (useTwoColumns)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 48,
                              child: SelectedReturnItemsCard(
                                items: selectedLines,
                                currency: currency,
                              ),
                            ),
                            const SizedBox(width: TenantAdminSpacing.lg),
                            Expanded(
                              flex: 52,
                              child: ReturnExchangeReasonCard(
                                reasons: reasonState.reasons,
                                selectedReasonCode:
                                    reasonState.selectedReasonCode,
                                notesController: notesController,
                                notesLength: reasonState.notes.length,
                                applySameReasonToAll:
                                    reasonState.applySameReasonToAll,
                                notesRequired: reasonState.notesRequired,
                                validationMessage:
                                    reasonState.validationMessage,
                                onReasonSelected: onReasonSelected,
                                onNotesChanged: onNotesChanged,
                                onApplySameReasonChanged:
                                    onApplySameReasonChanged,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        SelectedReturnItemsCard(
                          items: selectedLines,
                          currency: currency,
                        ),
                        const SizedBox(height: TenantAdminSpacing.lg),
                        ReturnExchangeReasonCard(
                          reasons: reasonState.reasons,
                          selectedReasonCode: reasonState.selectedReasonCode,
                          notesController: notesController,
                          notesLength: reasonState.notes.length,
                          applySameReasonToAll:
                              reasonState.applySameReasonToAll,
                          notesRequired: reasonState.notesRequired,
                          validationMessage: reasonState.validationMessage,
                          onReasonSelected: onReasonSelected,
                          onNotesChanged: onNotesChanged,
                          onApplySameReasonChanged: onApplySameReasonChanged,
                        ),
                      ],
                    ] else ...[
                      ReturnExchangeReasonCard(
                        reasons: reasonState.reasons,
                        selectedReasonCode: reasonState.selectedReasonCode,
                        notesController: notesController,
                        notesLength: reasonState.notes.length,
                        applySameReasonToAll: reasonState.applySameReasonToAll,
                        notesRequired: reasonState.notesRequired,
                        validationMessage: reasonState.validationMessage,
                        onReasonSelected: onReasonSelected,
                        onNotesChanged: onNotesChanged,
                        onApplySameReasonChanged: onApplySameReasonChanged,
                      ),
                      const SizedBox(height: TenantAdminSpacing.lg),
                      PerLineReturnReasonList(
                        items: selectedLines,
                        currency: currency,
                        reasons: reasonState.reasons,
                        lineSelections: reasonState.lineSelections,
                        showValidation: reasonState.showValidationMessage,
                        onReasonSelected: onLineReasonSelected,
                        onNotesChanged: onLineNotesChanged,
                      ),
                    ],
                    if (policyNote != null && policyNote!.isNotEmpty) ...[
                      const SizedBox(height: TenantAdminSpacing.lg),
                      ReturnPolicyInformationBanner(message: policyNote!),
                    ],
                    if (reasonState.saveErrorMessage != null) ...[
                      const SizedBox(height: TenantAdminSpacing.md),
                      Text(
                        reasonState.saveErrorMessage!,
                        style: const TextStyle(
                          color: TenantAdminColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            _ActionFooter(
              canContinue: canContinue,
              onBack: onBack,
              onContinue: onContinue,
            ),
          ],
        );
      },
    );
  }
}

class _ActionFooter extends StatelessWidget {
  const _ActionFooter({
    required this.canContinue,
    required this.onBack,
    required this.onContinue,
  });

  final bool canContinue;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < TenantAdminBreakpoints.mobile;
        final backButton = OutlinedButton(
          onPressed: onBack,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: TenantAdminColors.bodyText,
            side: const BorderSide(color: TenantAdminColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
          ),
          child: const Text('Back'),
        );
        final continueButton = PosPrimaryActionButton(
          label: 'Continue to Inspect Items',
          onPressed: canContinue ? onContinue : null,
          trailingIcon: Icons.arrow_forward_rounded,
          compact: true,
          borderRadius: TenantAdminRadius.sm,
        );

        if (compact) {
          return Row(
            children: [
              Expanded(child: backButton),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(flex: 2, child: continueButton),
            ],
          );
        }

        return Row(
          children: [
            SizedBox(width: 140, child: backButton),
            const Spacer(),
            SizedBox(width: 280, child: continueButton),
          ],
        );
      },
    );
  }
}

class _TopStatus extends ConsumerWidget {
  const _TopStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tillState = ref.watch(tillProvider);
    final session = tillState.session;
    final now = DateTime.now();
    final isOpen = tillState.hasOpenSession;
    final tillLabel = (session?.tillName.trim().isNotEmpty ?? false)
        ? session!.tillName.trim()
        : (session?.tillCode.trim().isNotEmpty ?? false)
            ? session!.tillCode.trim()
            : 'Till';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44,
          padding:
              const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: isOpen
                    ? TenantAdminColors.success
                    : TenantAdminColors.mutedText,
                size: 22,
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tillLabel, style: _statusText(context)),
                  Text(
                    isOpen ? 'Open' : 'Closed',
                    style: _statusText(context).copyWith(
                      color: isOpen
                          ? TenantAdminColors.success
                          : TenantAdminColors.mutedText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.xl),
        Text(
          _formatTime(now),
          style:
              _statusText(context).copyWith(color: TenantAdminColors.primary),
        ),
      ],
    );
  }

  TextStyle _statusText(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall?.copyWith(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w800,
            ) ??
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w800);
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
