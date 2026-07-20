import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_states.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../../domain/entities/return_resolution_type.dart';
import '../navigation/returns_route_guard.dart';
import '../providers/return_create_credit_provider.dart';
import '../providers/return_eligibility_provider.dart';
import '../providers/return_flow_provider.dart';
import '../providers/return_inspection_provider.dart';
import '../providers/return_reason_provider.dart';
import '../providers/return_resolution_provider.dart';
import '../widgets/choose_option/choose_option_header.dart';
import '../widgets/choose_option/choose_option_information_message.dart';
import '../widgets/choose_option/return_resolution_options.dart';
import '../widgets/return_stepper.dart';
import '../widgets/returns_exchange_action_footer.dart';

class PosReturnChooseOptionScreen extends ConsumerStatefulWidget {
  const PosReturnChooseOptionScreen({super.key});

  @override
  ConsumerState<PosReturnChooseOptionScreen> createState() =>
      _PosReturnChooseOptionScreenState();
}

class _PosReturnChooseOptionScreenState
    extends ConsumerState<PosReturnChooseOptionScreen> {
  bool _isContinuing = false;
  var _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureWorkflowContext();
    });
  }

  void _ensureWorkflowContext() {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canViewReturns(granted) ||
        !PosPermissionAccess.canCreateReturn(granted)) {
      return;
    }

    final flow = ref.read(returnFlowProvider);
    final eligibility = ref.read(returnEligibilityProvider);
    final reasonsValidated =
        flow.reasonsValidated || ref.read(returnReasonProvider).reasonsValidated;
    final inspectionsValidated = flow.inspectionsValidated ||
        ref.read(returnInspectionProvider).inspectionsValidated;

    if (!ReturnsRouteGuard.hasChooseOptionContext(
      flow: flow,
      eligibility: eligibility,
      reasonsValidated: reasonsValidated,
      inspectionsValidated: inspectionsValidated,
    )) {
      _redirectToLatestValidStep();
      return;
    }

    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.chooseOption);
    ref.read(returnResolutionProvider.notifier).loadSavedResolution();
  }

  void _redirectToLatestValidStep() {
    if (_redirectScheduled || !mounted) {
      return;
    }
    _redirectScheduled = true;

    final flow = ref.read(returnFlowProvider);
    final eligibility = ref.read(returnEligibilityProvider);
    final reasonsValidated =
        flow.reasonsValidated || ref.read(returnReasonProvider).reasonsValidated;

    if (ReturnsRouteGuard.hasInspectItemsContext(
      flow: flow,
      eligibility: eligibility,
      reasonsValidated: reasonsValidated,
    )) {
      context.go('/pos/returns-refunds/inspect-items');
      return;
    }

    if (ReturnsRouteGuard.hasReturnReasonContext(
      flow: flow,
      eligibility: eligibility,
    )) {
      context.go('/pos/returns-refunds/return-reason');
      return;
    }

    if (ReturnsRouteGuard.hasCheckEligibilityContext(flow)) {
      context.go('/pos/returns-refunds/check-eligibility');
      return;
    }

    context.go('/pos/returns-refunds/eligibility');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canViewReturns(granted) ||
        !PosPermissionAccess.canCreateReturn(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final resolutionState = ref.watch(returnResolutionProvider);
    if (resolutionState.isForbidden) {
      return const TenantAdminForbiddenScreen();
    }

    if (resolutionState.isLoading || resolutionState.savedResolution == null) {
      if (resolutionState.errorMessage != null && !resolutionState.isLoading) {
        return TenantAdminErrorState(
          title: 'Unable to load return options',
          message: resolutionState.errorMessage!,
          onRetry: () => ref
              .read(returnResolutionProvider.notifier)
              .loadSavedResolution(),
        );
      }
      return const ColoredBox(
        color: TenantAdminColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final flowState = ref.watch(returnFlowProvider);
    final eligibilityState = ref.watch(returnEligibilityProvider);
    final reasonsValidated = flowState.reasonsValidated ||
        ref.watch(returnReasonProvider).reasonsValidated;
    final inspectionsValidated = flowState.inspectionsValidated ||
        ref.watch(returnInspectionProvider).inspectionsValidated;

    if (!ReturnsRouteGuard.hasChooseOptionContext(
      flow: flowState,
      eligibility: eligibilityState,
      reasonsValidated: reasonsValidated,
      inspectionsValidated: inspectionsValidated,
    )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectToLatestValidStep();
      });
      return const ColoredBox(
        color: TenantAdminColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final authoritative = resolutionState.savedResolution!;
    final canSelectRefund = authoritative.refundAllowed;
    final canSelectExchange = authoritative.exchangeAllowed;
    final hasAnyBranchPermission = canSelectRefund || canSelectExchange;
    final selected = authoritative.resolutionType ?? flowState.selectedResolution;
    final canContinue = hasAnyBranchPermission &&
        selected != null &&
        ((selected == ReturnResolutionType.refund && canSelectRefund) ||
            (selected == ReturnResolutionType.exchange && canSelectExchange)) &&
        !resolutionState.isSaving;

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
                ReturnStepper(
                  currentStep: ReturnFlowSteps.chooseOption,
                  selectedBranch: flowState.selectedResolution,
                ),
                const SizedBox(height: TenantAdminSpacing.xl),
                Expanded(
                  child: hasAnyBranchPermission
                      ? _Body(
                          selectedResolution: selected,
                          refundEnabled: canSelectRefund,
                          exchangeEnabled: canSelectExchange,
                          onResolutionSelected: _selectResolution,
                          errorMessage: resolutionState.errorMessage,
                        )
                      : const TenantAdminEmptyState(
                          title: 'No authorised resolution',
                          message:
                              'You do not have permission to process a refund or exchange for this return.',
                          icon: Icons.lock_outline_rounded,
                        ),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                ReturnsExchangeActionFooter(
                  canContinue: canContinue && !_isContinuing,
                  isSubmitting: _isContinuing || resolutionState.isSaving,
                  onBack: _goBack,
                  onContinue: _continue,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectResolution(ReturnResolutionType resolution) {
    final authoritative =
        ref.read(returnResolutionProvider).savedResolution;
    if (authoritative == null) return;
    if (resolution == ReturnResolutionType.refund &&
        !authoritative.refundAllowed) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'You do not have permission to create refunds.',
      );
      return;
    }
    if (resolution == ReturnResolutionType.exchange &&
        !authoritative.exchangeAllowed) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'You do not have permission to create exchanges.',
      );
      return;
    }
    ref.read(returnFlowProvider.notifier).setSelectedResolution(resolution);
  }

  void _goBack() {
    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.inspectItems);
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/pos/returns-refunds/inspect-items');
  }

  Future<void> _continue() async {
    if (_isContinuing) {
      return;
    }

    final flowState = ref.read(returnFlowProvider);
    final resolution = flowState.selectedResolution;
    final authoritative =
        ref.read(returnResolutionProvider).savedResolution;
    if (resolution == null) {
      return;
    }

    if (resolution == ReturnResolutionType.refund &&
        authoritative?.refundAllowed != true) {
      return;
    }
    if (resolution == ReturnResolutionType.exchange &&
        authoritative?.exchangeAllowed != true) {
      return;
    }

    setState(() => _isContinuing = true);

    try {
      final saved = await ref
          .read(returnResolutionProvider.notifier)
          .saveResolution(resolution);
      if (!saved) {
        if (!mounted) {
          return;
        }
        final error = ref.read(returnResolutionProvider).errorMessage;
        if (ref.read(returnResolutionProvider).isForbidden) {
          return;
        }
        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
        return;
      }

      switch (resolution) {
        case ReturnResolutionType.refund:
          if (flowState.refundPreview == null) {
            await ref.read(returnCreateCreditProvider.notifier).load();
            final preview = ref.read(returnCreateCreditProvider).preview;
            if (preview == null) {
              if (!mounted) {
                return;
              }
              final error = ref.read(returnCreateCreditProvider).errorMessage;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    error ??
                        'Unable to load refund preview. Please try again.',
                  ),
                ),
              );
              return;
            }
            ref.read(returnFlowProvider.notifier).setRefundPreview(preview);
          }

          ref
              .read(returnFlowProvider.notifier)
              .setStep(ReturnFlowSteps.branchAction);
          if (!mounted) {
            return;
          }
          await context.push('/pos/returns-refunds/refund-details');
          if (mounted) {
            await ref
                .read(returnResolutionProvider.notifier)
                .loadSavedResolution();
          }
        case ReturnResolutionType.exchange:
          if (flowState.refundPreview == null) {
            await ref.read(returnCreateCreditProvider.notifier).load();
            final preview = ref.read(returnCreateCreditProvider).preview;
            if (preview == null) {
              if (!mounted) {
                return;
              }
              final error = ref.read(returnCreateCreditProvider).errorMessage;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    error ??
                        'Unable to load return value preview. Please try again.',
                  ),
                ),
              );
              return;
            }
            ref.read(returnFlowProvider.notifier).setRefundPreview(preview);
          }

          ref
              .read(returnFlowProvider.notifier)
              .setStep(ReturnFlowSteps.branchAction);
          if (!mounted) {
            return;
          }
          await context.push('/pos/returns-refunds/exchange');
          if (mounted) {
            await ref
                .read(returnResolutionProvider.notifier)
                .loadSavedResolution();
          }
      }
    } finally {
      if (mounted) {
        setState(() => _isContinuing = false);
      }
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.selectedResolution,
    required this.onResolutionSelected,
    required this.refundEnabled,
    required this.exchangeEnabled,
    this.errorMessage,
  });

  final ReturnResolutionType? selectedResolution;
  final ValueChanged<ReturnResolutionType> onResolutionSelected;
  final bool refundEnabled;
  final bool exchangeEnabled;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxContentWidth = constraints.maxWidth >= 960
            ? 760.0
            : constraints.maxWidth;

        return SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ChooseOptionHeader(),
                  SizedBox(
                    height: constraints.maxWidth >= TenantAdminBreakpoints.tablet
                        ? TenantAdminSpacing.xxl
                        : TenantAdminSpacing.xl,
                  ),
                  ReturnResolutionOptions(
                    selectedResolution: selectedResolution,
                    onResolutionSelected: onResolutionSelected,
                    refundEnabled: refundEnabled,
                    exchangeEnabled: exchangeEnabled,
                  ),
                  if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                    const SizedBox(height: TenantAdminSpacing.md),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: TenantAdminColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  const SizedBox(height: TenantAdminSpacing.xl),
                  const ChooseOptionInformationMessage(),
                ],
              ),
            ),
          ),
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
              Text(tillLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.xl),
        Text(
          '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}',
        ),
      ],
    );
  }
}
