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
import '../../domain/entities/return_sale_eligibility.dart';
import '../navigation/returns_route_guard.dart';
import '../providers/return_eligibility_provider.dart';
import '../providers/return_flow_provider.dart';
import '../widgets/eligibility_check/eligibility_check_header.dart';
import '../widgets/eligibility_check/eligibility_checklist_card.dart';
import '../widgets/eligibility_check/eligibility_result_banner.dart';
import '../widgets/eligibility_check/eligibility_summary_card.dart';
import '../widgets/return_stepper.dart';

class PosReturnCheckEligibilityScreen extends ConsumerStatefulWidget {
  const PosReturnCheckEligibilityScreen({super.key});

  @override
  ConsumerState<PosReturnCheckEligibilityScreen> createState() =>
      _PosReturnCheckEligibilityScreenState();
}

class _PosReturnCheckEligibilityScreenState
    extends ConsumerState<PosReturnCheckEligibilityScreen> {
  var _bannerDismissed = false;
  var _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapStep();
    });
  }

  void _bootstrapStep() {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canViewReturns(granted)) {
      return;
    }

    final flowState = ref.read(returnFlowProvider);
    if (!ReturnsRouteGuard.hasCheckEligibilityContext(flowState)) {
      _redirectToSelectItems();
      return;
    }

    ref
        .read(returnFlowProvider.notifier)
        .setStep(ReturnFlowSteps.checkEligibility);
    _runEligibilityCheck();
  }

  void _redirectToSelectItems() {
    if (_redirectScheduled || !mounted) {
      return;
    }
    _redirectScheduled = true;
    context.go('/pos/returns-refunds/eligibility');
  }

  Future<void> _runEligibilityCheck() async {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canViewReturns(granted)) {
      return;
    }

    final flowState = ref.read(returnFlowProvider);
    if (!ReturnsRouteGuard.hasCheckEligibilityContext(flowState)) {
      _redirectToSelectItems();
      return;
    }

    final sale = flowState.selectedSale!;
    final selectedLines = flowState.selectedReturnLines;

    await ref.read(returnEligibilityProvider.notifier).validateSelectedLines(
      saleId: sale.saleId,
      lines: [
        for (final line in selectedLines)
          ReturnLineSelection(
            saleLineId: line.saleLineId,
            isSelected: true,
            returnQty: line.returnQty,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canViewReturns(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final flowState = ref.watch(returnFlowProvider);
    final eligibilityState = ref.watch(returnEligibilityProvider);

    if (eligibilityState.checkPermissionDenied) {
      return const TenantAdminForbiddenScreen();
    }

    if (!ReturnsRouteGuard.hasCheckEligibilityContext(flowState)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectToSelectItems();
      });
      return const ColoredBox(
        color: TenantAdminColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final checkResult = eligibilityState.checkResult;
    final canContinue = ReturnsRouteGuard.canContinueFromEligibilityCheck(
      granted: granted,
      flow: flowState,
      eligibility: eligibilityState,
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
                const ReturnStepper(
                  currentStep: ReturnFlowSteps.checkEligibility,
                ),
                const SizedBox(height: TenantAdminSpacing.xl),
                Expanded(
                  child: _Body(
                    selectedSaleMissing: flowState.selectedSale == null,
                    selectedLinesMissing: flowState.selectedReturnLines.isEmpty,
                    eligibilityState: eligibilityState,
                    checkResult: checkResult,
                    canContinue: canContinue,
                    bannerDismissed: _bannerDismissed,
                    onDismissBanner: () =>
                        setState(() => _bannerDismissed = true),
                    onRetry: _runEligibilityCheck,
                    onBack: _goBack,
                    onContinue: _continueToReturnReason,
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
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/pos/returns-refunds/eligibility');
  }

  void _continueToReturnReason() {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    final flowState = ref.read(returnFlowProvider);
    final eligibilityState = ref.read(returnEligibilityProvider);

    if (!ReturnsRouteGuard.canContinueFromEligibilityCheck(
      granted: granted,
      flow: flowState,
      eligibility: eligibilityState,
    )) {
      if (!PosPermissionAccess.canCreateReturn(granted)) {
        PosPermissionAccess.showAccessDeniedSnackBar(
          context,
          'You do not have permission to continue this return.',
        );
      }
      return;
    }

    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.returnReason);
    context.push('/pos/returns-refunds/return-reason');
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.selectedSaleMissing,
    required this.selectedLinesMissing,
    required this.eligibilityState,
    required this.checkResult,
    required this.canContinue,
    required this.bannerDismissed,
    required this.onDismissBanner,
    required this.onRetry,
    required this.onBack,
    required this.onContinue,
  });

  final bool selectedSaleMissing;
  final bool selectedLinesMissing;
  final ReturnEligibilityState eligibilityState;
  final ReturnSaleEligibility? checkResult;
  final bool canContinue;
  final bool bannerDismissed;
  final VoidCallback onDismissBanner;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    if (selectedSaleMissing || selectedLinesMissing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            child: TenantAdminEmptyState(
              title: 'Selected items required',
              message:
                  'Go back to Select Items and choose at least one sale line before checking eligibility.',
              icon: Icons.fact_check_outlined,
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

    if (eligibilityState.isChecking) {
      return const Center(child: CircularProgressIndicator());
    }

    if (eligibilityState.checkErrorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TenantAdminErrorState(
              title: 'Unable to validate eligibility',
              message: eligibilityState.checkErrorMessage!,
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

    final result = checkResult;
    if (result == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            child: TenantAdminEmptyState(
              title: 'No eligibility results',
              message:
                  'Eligibility results are unavailable for the selected items.',
              icon: Icons.fact_check_outlined,
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
                    const EligibilityCheckHeader(),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    if (!bannerDismissed) ...[
                      EligibilityResultBanner(
                        result: result,
                        onDismiss: onDismissBanner,
                      ),
                      const SizedBox(height: TenantAdminSpacing.lg),
                    ],
                    if (useTwoColumns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 62,
                            child: EligibilityChecklistCard(
                              checks: result.policyChecks,
                            ),
                          ),
                          const SizedBox(width: TenantAdminSpacing.lg),
                          Expanded(
                            flex: 38,
                            child: EligibilitySummaryCard(result: result),
                          ),
                        ],
                      )
                    else ...[
                      EligibilityChecklistCard(checks: result.policyChecks),
                      const SizedBox(height: TenantAdminSpacing.lg),
                      EligibilitySummaryCard(result: result),
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
          label: 'Continue',
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
            SizedBox(width: 220, child: continueButton),
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
