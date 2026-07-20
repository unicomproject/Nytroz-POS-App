import 'package:flutter/material.dart';
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_states.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../../domain/entities/return_inspection.dart';
import '../navigation/returns_route_guard.dart';
import '../providers/return_eligibility_provider.dart';
import '../providers/return_flow_provider.dart';
import '../providers/return_inspection_provider.dart';
import '../providers/return_reason_provider.dart';
import '../widgets/inspect_items/inspect_items_header.dart';
import '../widgets/inspect_items/inspection_condition_breakdown_card.dart';
import '../widgets/inspect_items/inspection_item_card.dart';
import '../widgets/inspect_items/inspection_policy_warning_card.dart';
import '../widgets/inspect_items/inspection_summary_card.dart';
import '../widgets/return_stepper.dart';

class PosReturnInspectItemsScreen extends ConsumerStatefulWidget {
  const PosReturnInspectItemsScreen({super.key});

  @override
  ConsumerState<PosReturnInspectItemsScreen> createState() =>
      _PosReturnInspectItemsScreenState();
}

class _PosReturnInspectItemsScreenState
    extends ConsumerState<PosReturnInspectItemsScreen> {
  final _notesControllers = <String, TextEditingController>{};
  final _imagePicker = ImagePicker();
  var _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeInspection();
    });
  }

  Future<void> _initializeInspection() async {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canViewReturns(granted) ||
        !PosPermissionAccess.canCreateReturn(granted)) {
      return;
    }

    final flowState = ref.read(returnFlowProvider);
    final eligibilityState = ref.read(returnEligibilityProvider);
    final reasonsValidated = flowState.reasonsValidated ||
        ref.read(returnReasonProvider).reasonsValidated;
    if (!ReturnsRouteGuard.hasInspectItemsContext(
      flow: flowState,
      eligibility: eligibilityState,
      reasonsValidated: reasonsValidated,
    )) {
      _redirectToReturnReason();
      return;
    }

    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.inspectItems);

    final saleId = flowState.selectedSale?.saleId;
    if (saleId == null || saleId.isEmpty) {
      _redirectToReturnReason();
      return;
    }

    await ref.read(returnInspectionProvider.notifier).load(
          saleId: saleId,
          selectedLines: flowState.selectedReturnLines,
          existingInspections: flowState.lineInspections.isEmpty
              ? null
              : flowState.lineInspections,
        );

    if (!mounted) {
      return;
    }

    _syncControllers(ref.read(returnInspectionProvider).lineInspections);
  }

  void _redirectToReturnReason() {
    if (_redirectScheduled || !mounted) {
      return;
    }
    _redirectScheduled = true;
    context.go('/pos/returns-refunds/return-reason');
  }

  void _syncControllers(Map<String, ReturnLineInspection> inspections) {
    for (final entry in inspections.entries) {
      final controller = _notesControllers.putIfAbsent(
        entry.key,
        () => TextEditingController(text: entry.value.notes),
      );
      if (controller.text != entry.value.notes) {
        controller.text = entry.value.notes;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
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
    final reasonsValidated = flowState.reasonsValidated ||
        ref.watch(returnReasonProvider).reasonsValidated;

    if (!ReturnsRouteGuard.hasInspectItemsContext(
      flow: flowState,
      eligibility: eligibilityState,
      reasonsValidated: reasonsValidated,
    )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectToReturnReason();
      });
      return const ColoredBox(
        color: TenantAdminColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final inspectionState = ref.watch(returnInspectionProvider);
    if (inspectionState.permissionDenied) {
      return const TenantAdminForbiddenScreen();
    }

    final currency = flowState.selectedSale?.currency ?? '';
    final canContinue = ReturnsRouteGuard.canContinueFromInspection(
      granted: granted,
      flow: flowState,
      eligibility: eligibilityState,
      reasonsValidated: reasonsValidated,
      localCanContinue: inspectionState.canContinue,
      isValidating: inspectionState.isValidating,
      hasUploadInProgress: inspectionState.hasUploadInProgress,
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
                const ReturnStepper(currentStep: ReturnFlowSteps.inspectItems),
                const SizedBox(height: TenantAdminSpacing.xl),
                Expanded(
                  child: _Body(
                    flowState: flowState,
                    inspectionState: inspectionState,
                    canContinue: canContinue,
                    currency: currency,
                    notesControllers: _notesControllers,
                    policyMessages: _policyMessages(inspectionState),
                    onRetry: _initializeInspection,
                    onBack: _goBack,
                    onContinue: _continueToChooseOption,
                    onConditionSelected: (saleLineId, code) {
                      ref
                          .read(returnInspectionProvider.notifier)
                          .selectCondition(
                            saleLineId: saleLineId,
                            conditionCode: code,
                          );
                    },
                    onNotesChanged: (saleLineId, value) {
                      ref.read(returnInspectionProvider.notifier).setNotes(
                            saleLineId: saleLineId,
                            notes: value,
                          );
                    },
                    onAddPhoto: _pickPhoto,
                    onRemovePhoto: (saleLineId, mediaId) {
                      ref.read(returnInspectionProvider.notifier).removePhoto(
                            saleLineId: saleLineId,
                            mediaId: mediaId,
                          );
                    },
                    onRetryPhoto: (saleLineId, mediaId) {
                      // Retry requires re-picking; remove failed placeholder first.
                      ref.read(returnInspectionProvider.notifier).removePhoto(
                            saleLineId: saleLineId,
                            mediaId: mediaId,
                          );
                      _pickPhoto(saleLineId);
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

  List<InspectionPolicyMessage> _policyMessages(ReturnInspectionState state) {
    if (state.policyMessages.isNotEmpty) {
      return state.policyMessages;
    }

    if (state.validationResult == null && !state.inspectionsValidated) {
      return const [returnInspectionPreValidateGuidance];
    }

    return const [];
  }

  Future<void> _pickPhoto(String saleLineId) async {
    final sale = ref.read(returnFlowProvider).selectedSale;
    if (sale == null) {
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) {
      return;
    }

    await ref.read(returnInspectionProvider.notifier).addPhoto(
          saleId: sale.saleId,
          saleLineId: saleLineId,
          filePath: image.path,
          fileName: image.name,
        );
  }

  void _goBack() {
    final inspectionState = ref.read(returnInspectionProvider);
    ref.read(returnFlowProvider.notifier).setLineInspections(
          inspectionState.lineInspections,
        );

    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/pos/returns-refunds/return-reason');
  }

  Future<void> _continueToChooseOption() async {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    final flowState = ref.read(returnFlowProvider);
    final eligibilityState = ref.read(returnEligibilityProvider);
    final reasonsValidated = flowState.reasonsValidated ||
        ref.read(returnReasonProvider).reasonsValidated;
    final inspectionState = ref.read(returnInspectionProvider);

    if (!ReturnsRouteGuard.canContinueFromInspection(
      granted: granted,
      flow: flowState,
      eligibility: eligibilityState,
      reasonsValidated: reasonsValidated,
      localCanContinue: inspectionState.canContinue,
      isValidating: inspectionState.isValidating,
      hasUploadInProgress: inspectionState.hasUploadInProgress,
    )) {
      if (!PosPermissionAccess.canCreateReturn(granted)) {
        PosPermissionAccess.showAccessDeniedSnackBar(
          context,
          'You do not have permission to continue this return.',
        );
        return;
      }

      final saleId = flowState.selectedSale?.saleId;
      if (saleId != null && saleId.isNotEmpty) {
        await ref
            .read(returnInspectionProvider.notifier)
            .validateAndContinue(saleId: saleId);
      }
      return;
    }

    final sale = flowState.selectedSale;
    if (sale == null) {
      return;
    }

    final isValid = await ref
        .read(returnInspectionProvider.notifier)
        .validateAndContinue(saleId: sale.saleId);
    if (!isValid || !mounted) {
      return;
    }

    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.chooseOption);

    context.push('/pos/returns-refunds/choose-option');
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.flowState,
    required this.inspectionState,
    required this.canContinue,
    required this.currency,
    required this.notesControllers,
    required this.policyMessages,
    required this.onRetry,
    required this.onBack,
    required this.onContinue,
    required this.onConditionSelected,
    required this.onNotesChanged,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onRetryPhoto,
  });

  final ReturnFlowState flowState;
  final ReturnInspectionState inspectionState;
  final bool canContinue;
  final String currency;
  final Map<String, TextEditingController> notesControllers;
  final List<InspectionPolicyMessage> policyMessages;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final void Function(String saleLineId, String code) onConditionSelected;
  final void Function(String saleLineId, String value) onNotesChanged;
  final void Function(String saleLineId) onAddPhoto;
  final void Function(String saleLineId, String mediaId) onRemovePhoto;
  final void Function(String saleLineId, String mediaId) onRetryPhoto;

  @override
  Widget build(BuildContext context) {
    final selectedLines = flowState.selectedReturnLines;

    if (selectedLines.isEmpty || flowState.selectedSale == null) {
      return Column(
        children: [
          const Expanded(
            child: TenantAdminEmptyState(
              title: 'No items selected',
              message:
                  'Go back and select return items before inspecting condition.',
              icon: Icons.inventory_2_outlined,
            ),
          ),
          _ActionFooter(
            canContinue: false,
            isSubmitting: false,
            onBack: onBack,
            onContinue: onContinue,
          ),
        ],
      );
    }

    if (inspectionState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (inspectionState.errorMessage != null &&
        inspectionState.conditions.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: TenantAdminErrorState(
              title: 'Unable to load inspection options',
              message: inspectionState.errorMessage!,
              onRetry: onRetry,
            ),
          ),
          _ActionFooter(
            canContinue: false,
            isSubmitting: false,
            onBack: onBack,
            onContinue: onContinue,
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 960;

        final list = Column(
          children: [
            for (var index = 0; index < selectedLines.length; index += 1) ...[
              if (index > 0) const SizedBox(height: TenantAdminSpacing.lg),
              Builder(
                builder: (context) {
                  final line = selectedLines[index];
                  final inspection =
                      inspectionState.lineInspections[line.saleLineId] ??
                          ReturnLineInspection(saleLineId: line.saleLineId);
                  final controller = notesControllers.putIfAbsent(
                    line.saleLineId,
                    () => TextEditingController(text: inspection.notes),
                  );

                  return InspectionItemCard(
                    itemName: line.name,
                    sku: line.sku,
                    variantLabel: line.variantLabel,
                    quantity: line.returnQty,
                    valueLabel: formatReturnEligibilityAmount(
                      currency: currency,
                      amount: line.lineTotal,
                    ),
                    imageValue: line.imageStorageKey,
                    conditions: inspectionState.conditions,
                    inspection: inspection,
                    notesMaxLength: inspectionState.notesMaxLength,
                    maxPhotosPerLine: inspectionState.maxPhotosPerLine,
                    notesController: controller,
                    onConditionSelected: (code) =>
                        onConditionSelected(line.saleLineId, code),
                    onNotesChanged: (value) =>
                        onNotesChanged(line.saleLineId, value),
                    onAddPhoto: () => onAddPhoto(line.saleLineId),
                    onRemovePhoto: (mediaId) =>
                        onRemovePhoto(line.saleLineId, mediaId),
                    onRetryPhoto: (mediaId) =>
                        onRetryPhoto(line.saleLineId, mediaId),
                  );
                },
              ),
            ],
          ],
        );

        final summaryColumn = Column(
          children: [
            InspectionSummaryCard(state: inspectionState),
            const SizedBox(height: TenantAdminSpacing.lg),
            InspectionConditionBreakdownCard(state: inspectionState),
            const SizedBox(height: TenantAdminSpacing.lg),
            InspectionPolicyWarningCard(messages: policyMessages),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const InspectItemsHeader(),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    if (useTwoColumns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 74, child: list),
                          const SizedBox(width: TenantAdminSpacing.lg),
                          Expanded(flex: 26, child: summaryColumn),
                        ],
                      )
                    else ...[
                      list,
                      const SizedBox(height: TenantAdminSpacing.lg),
                      summaryColumn,
                    ],
                    if (inspectionState.showValidationMessage &&
                        !inspectionState.canContinue) ...[
                      const SizedBox(height: TenantAdminSpacing.md),
                      Text(
                        'Complete condition, required notes, and photo uploads for all selected items.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              isSubmitting: inspectionState.isValidating,
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
    required this.isSubmitting,
    required this.onBack,
    required this.onContinue,
  });

  final bool canContinue;
  final bool isSubmitting;
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
          label: 'Continue to Choose Option',
          onPressed: canContinue && !isSubmitting ? onContinue : null,
          isLoading: isSubmitting,
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
            SizedBox(width: 300, child: continueButton),
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
