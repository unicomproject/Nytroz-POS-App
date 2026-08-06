import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_states.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../../domain/entities/return_refund_method.dart';
import '../../domain/entities/return_resolution_type.dart';
import '../navigation/returns_route_guard.dart';
import '../providers/return_flow_provider.dart';
import '../providers/return_refund_details_provider.dart';
import '../providers/return_resolution_provider.dart';
import '../widgets/refund_details/refund_amount_section.dart';
import '../widgets/refund_details/refund_details_header.dart';
import '../widgets/refund_details/refund_method_section.dart';
import '../widgets/refund_details/refund_summary_card.dart';
import '../widgets/return_stepper.dart';
import '../widgets/returns_exchange_action_footer.dart';

class PosReturnRefundDetailsScreen extends ConsumerStatefulWidget {
  const PosReturnRefundDetailsScreen({super.key});

  @override
  ConsumerState<PosReturnRefundDetailsScreen> createState() =>
      _PosReturnRefundDetailsScreenState();
}

class _PosReturnRefundDetailsScreenState
    extends ConsumerState<PosReturnRefundDetailsScreen> {
  bool _isGuarding = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardAndLoad());
  }

  Future<void> _guardAndLoad() async {
    final loaded =
        await ref.read(returnResolutionProvider.notifier).loadSavedResolution();
    final authoritative = ref.read(returnResolutionProvider).savedResolution;
    if (!loaded ||
        authoritative == null ||
        !authoritative.isValidated ||
        !authoritative.refundAllowed ||
        authoritative.resolutionType != ReturnResolutionType.refund) {
      if (mounted) context.go('/pos/returns-refunds/choose-option');
      return;
    }
    if (mounted) setState(() => _isGuarding = false);
    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.branchAction);
    ref.read(returnRefundDetailsProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canProcessRefund(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    if (_isGuarding) {
      return const ColoredBox(
        color: TenantAdminColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final flowState = ref.watch(returnFlowProvider);
    final detailsState = ref.watch(returnRefundDetailsProvider);
    final preview = detailsState.preview ?? flowState.refundPreview;
    final branchMismatch = !ReturnsRouteGuard.hasRefundBranchContext(flowState);

    if (detailsState.isForbidden) {
      return const TenantAdminForbiddenScreen();
    }

    return ColoredBox(
      color: TenantAdminColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth >= TenantAdminBreakpoints.tablet
              ? const EdgeInsets.fromLTRB(22, 20, 22, 22)
              : TenantAdminInsets.pageForWidth(constraints.maxWidth);
          final twoColumn = constraints.maxWidth >= 760;

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
                  currentStep: ReturnFlowSteps.branchAction,
                  selectedBranch: flowState.selectedResolution,
                ),
                const SizedBox(height: TenantAdminSpacing.xl),
                const RefundDetailsHeader(),
                const SizedBox(height: TenantAdminSpacing.lg),
                Expanded(
                  child: branchMismatch
                      ? const TenantAdminEmptyState(
                          title: 'Refund branch not selected',
                          message:
                              'Return to Choose Option and select Refund to continue this step.',
                          icon: Icons.alt_route_rounded,
                        )
                      : detailsState.isLoading && preview == null
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(TenantAdminSpacing.xl),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : preview == null
                              ? TenantAdminEmptyState(
                                  title: 'Refund preview unavailable',
                                  message: detailsState.errorMessage ??
                                      'Return to Choose Option and continue again to load refund details.',
                                  icon: Icons.receipt_long_outlined,
                                )
                              : SingleChildScrollView(
                                  child: twoColumn
                                      ? Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: _DetailsColumn(
                                                preview: preview,
                                                detailsState: detailsState,
                                                onMethodSelected: (method) {
                                                  ref
                                                      .read(
                                                        returnRefundDetailsProvider
                                                            .notifier,
                                                      )
                                                      .selectMethod(method);
                                                },
                                              ),
                                            ),
                                            const SizedBox(
                                              width: TenantAdminSpacing.xl,
                                            ),
                                            Expanded(
                                              child: RefundSummaryCard(
                                                preview: preview,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _DetailsColumn(
                                              preview: preview,
                                              detailsState: detailsState,
                                              onMethodSelected: (method) {
                                                ref
                                                    .read(
                                                      returnRefundDetailsProvider
                                                          .notifier,
                                                    )
                                                    .selectMethod(method);
                                              },
                                            ),
                                            const SizedBox(
                                              height: TenantAdminSpacing.lg,
                                            ),
                                            RefundSummaryCard(preview: preview),
                                          ],
                                        ),
                                ),
                ),
                if (preview != null &&
                    preview.requiresApproval &&
                    (preview.policyMessage?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: TenantAdminSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(TenantAdminSpacing.md),
                    decoration: BoxDecoration(
                      color: TenantAdminColors.surface,
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                      border: Border.all(color: TenantAdminColors.warning),
                    ),
                    child: Text(
                      preview.policyMessage!.trim(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: TenantAdminSpacing.lg),
                ReturnsExchangeActionFooter(
                  canContinue:
                      preview != null && _canConfirm(detailsState, preview),
                  isSubmitting: detailsState.isSavingMethod,
                  continueLabel: 'Confirm Refund',
                  onBack: _goBack,
                  onContinue: _confirmRefund,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _canConfirm(
    ReturnRefundDetailsState detailsState,
    ReturnCreditPreview preview,
  ) {
    return detailsState.canConfirm;
  }

  void _goBack() {
    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.chooseOption);
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/pos/returns-refunds/choose-option');
  }

  Future<void> _confirmRefund() async {
    final detailsState = ref.read(returnRefundDetailsProvider);
    final preview =
        detailsState.preview ?? ref.read(returnFlowProvider).refundPreview;
    if (preview == null || !_canConfirm(detailsState, preview)) {
      return;
    }

    final saved = detailsState.methodPersisted
        ? true
        : await ref
            .read(returnRefundDetailsProvider.notifier)
            .persistSelectedMethod();
    if (!saved || !mounted) {
      final error = ref.read(returnRefundDetailsProvider).errorMessage;
      if (error != null && error.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
      return;
    }

    ref.read(returnFlowProvider.notifier).setCreditPreviewConfirmed(true);
    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.settlement);

    if (!mounted) {
      return;
    }

    await context.push('/pos/returns-refunds/settlement');
  }
}

class _DetailsColumn extends StatelessWidget {
  const _DetailsColumn({
    required this.preview,
    required this.detailsState,
    required this.onMethodSelected,
  });

  final ReturnCreditPreview preview;
  final ReturnRefundDetailsState detailsState;
  final ValueChanged<ReturnRefundMethodOption> onMethodSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RefundAmountSection(
            currency: preview.currency,
            amount: preview.calculation.netCreditAmount,
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          RefundMethodSection(
            methods: detailsState.methods,
            selectedMethodCode: detailsState.selectedMethodCode,
            isLoading: detailsState.isLoadingMethods,
            onMethodSelected: onMethodSelected,
          ),
        ],
      ),
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
              Text(tillLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
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
