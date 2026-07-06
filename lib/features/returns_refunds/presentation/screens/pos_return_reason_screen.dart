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
import '../providers/return_reason_provider.dart';
import '../widgets/return_continue_footer.dart';
import '../widgets/return_reason_notes_field.dart';
import '../widgets/return_reason_options_section.dart';
import '../widgets/return_reason_validation_message.dart';
import '../widgets/return_selected_items_section.dart';
import '../widgets/return_stepper.dart';

class PosReturnReasonScreen extends ConsumerStatefulWidget {
  const PosReturnReasonScreen({super.key});

  @override
  ConsumerState<PosReturnReasonScreen> createState() =>
      _PosReturnReasonScreenState();
}

class _PosReturnReasonScreenState extends ConsumerState<PosReturnReasonScreen> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.returnReason);

      final flowState = ref.read(returnFlowProvider);
      ref.read(returnReasonProvider.notifier).hydrate(
            selectedReasonCode: flowState.selectedReasonCode,
            notes: flowState.returnNotes,
          );
      _notesController.text = flowState.returnNotes;
    });
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

    if (!PosPermissionAccess.canViewReturnsOrRefunds(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final flowState = ref.watch(returnFlowProvider);
    final reasonState = ref.watch(returnReasonProvider);
    final selectedLines = flowState.selectedReturnLines;
    final hasSelectedLines = selectedLines.isNotEmpty;
    final showValidation =
        reasonState.showValidationMessage || !reasonState.hasSelectedReason;

    return ColoredBox(
      color: TenantAdminColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);

          return Padding(
            padding: padding,
            child: SizedBox.expand(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(onBack: _goBack),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  const ReturnStepper(currentStep: ReturnFlowSteps.returnReason),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  if (!hasSelectedLines)
                    const Expanded(
                      child: TenantAdminEmptyState(
                        title: 'No items selected',
                        message:
                            'Go back and select return items before choosing a reason.',
                        icon: Icons.assignment_return_outlined,
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ReturnSelectedItemsSection(items: selectedLines),
                            const SizedBox(height: TenantAdminSpacing.xl),
                            ReturnReasonOptionsSection(
                              selectedReasonCode: reasonState.selectedReasonCode,
                              onReasonSelected: ref
                                  .read(returnReasonProvider.notifier)
                                  .selectReason,
                            ),
                            const SizedBox(height: TenantAdminSpacing.xl),
                            ReturnReasonNotesField(
                              controller: _notesController,
                              notesLength: reasonState.notes.length,
                              onChanged: ref
                                  .read(returnReasonProvider.notifier)
                                  .setNotes,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  if (hasSelectedLines && showValidation)
                    const ReturnReasonValidationMessage(),
                  if (hasSelectedLines && showValidation)
                    const SizedBox(height: TenantAdminSpacing.md),
                  ReturnContinueFooter(
                    canContinue: hasSelectedLines,
                    cancelLabel: 'Back',
                    continueLabel: 'Continue to Create Credit',
                    onCancel: _goBack,
                    onContinue: _continueToCreateCredit,
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
    context.go('/pos/returns-refunds/eligibility');
  }

  void _continueToCreateCredit() {
    if (!ref.read(returnReasonProvider.notifier).validate()) {
      return;
    }

    final reasonState = ref.read(returnReasonProvider);
    final reasonCode = reasonState.selectedReasonCode;
    if (reasonCode == null) {
      return;
    }

    ref.read(returnFlowProvider.notifier)
      ..setReturnReason(
        reasonCode: reasonCode,
        notes: reasonState.notes,
      )
      ..setStep(ReturnFlowSteps.createCredit);

    context.push('/pos/returns-refunds/create-credit');
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
          tooltip: 'Back to Eligibility',
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
                'Select Return Reason',
                style: TenantAdminTextStyles.pageTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                'Capture the reason for each item being returned.',
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
