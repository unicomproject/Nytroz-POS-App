import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_states.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../domain/entities/exchange_difference_result.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../../domain/entities/return_exchange.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../../domain/entities/return_resolution_type.dart';
import '../navigation/returns_route_guard.dart';
import '../providers/return_exchange_flow_provider.dart';
import '../providers/return_flow_provider.dart';
import '../providers/return_inspection_provider.dart';
import '../providers/return_resolution_provider.dart';
import '../providers/return_review_provider.dart';
import '../widgets/return_stepper.dart';
import '../widgets/review_confirm/exchange_settlement_details_card.dart';
import '../widgets/review_confirm/refund_settlement_details_card.dart';
import '../widgets/review_confirm/return_exchange_review_action_footer.dart';
import '../widgets/review_confirm/return_exchange_review_header.dart';
import '../widgets/review_confirm/return_financial_summary_card.dart';
import '../widgets/review_confirm/return_reference_details_card.dart';
import '../widgets/review_confirm/return_review_items_section.dart';
import '../widgets/review_confirm/settlement_information_banner.dart';

class PosReturnSettlementScreen extends ConsumerStatefulWidget {
  const PosReturnSettlementScreen({super.key});

  @override
  ConsumerState<PosReturnSettlementScreen> createState() =>
      _PosReturnSettlementScreenState();
}

class _PosReturnSettlementScreenState
    extends ConsumerState<PosReturnSettlementScreen> {
  bool _isGuarding = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardAndLoad());
  }

  Future<void> _guardAndLoad() async {
    final flow = ref.read(returnFlowProvider);
    final isExchange = flow.selectedResolution == ReturnResolutionType.exchange;

    final loaded =
        await ref.read(returnResolutionProvider.notifier).loadSavedResolution();
    final authoritative = ref.read(returnResolutionProvider).savedResolution;
    if (!loaded ||
        authoritative == null ||
        !authoritative.isValidated ||
        (isExchange
            ? (!authoritative.exchangeAllowed ||
                authoritative.resolutionType != ReturnResolutionType.exchange)
            : (!authoritative.refundAllowed ||
                authoritative.resolutionType != ReturnResolutionType.refund))) {
      if (mounted) {
        context.go('/pos/returns-refunds/choose-option');
      }
      return;
    }

    if (isExchange) {
      if (!ReturnsRouteGuard.hasExchangeBranchContext(
          ref.read(returnFlowProvider))) {
        if (mounted) {
          context.go('/pos/returns-refunds/choose-option');
        }
        return;
      }
      await ref.read(returnExchangeFlowProvider.notifier).hydrate();
      if (!mounted) {
        return;
      }
      ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.settlement);
      final exchangeState = ref.read(returnExchangeFlowProvider);
      final latestFlow = ref.read(returnFlowProvider);
      if (!ReturnsRouteGuard.hasExchangeBranchContext(latestFlow) ||
          !exchangeState.replacementPersisted) {
        context.go('/pos/returns-refunds/exchange');
        return;
      }
      if (mounted) setState(() => _isGuarding = false);
      await ref.read(returnReviewProvider.notifier).loadPreview();
      return;
    }

    if (!ReturnsRouteGuard.hasRefundBranchContext(
        ref.read(returnFlowProvider))) {
      if (mounted) {
        context.go('/pos/returns-refunds/choose-option');
      }
      return;
    }

    if (mounted) setState(() => _isGuarding = false);
    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.settlement);
    await ref.read(returnReviewProvider.notifier).loadPreview();
  }

  Map<String, String> _conditionLabels(ReturnFlowState flowState) {
    final conditions = ref.read(returnInspectionProvider).conditions;
    final labels = <String, String>{};

    for (final entry in flowState.lineInspections.entries) {
      final code = entry.value.conditionCode;
      if (code == null || code.isEmpty) {
        labels[entry.key] = '-';
        continue;
      }

      final match = conditions.where((c) => c.code == code);
      labels[entry.key] = match.isEmpty ? code : match.first.displayName;
    }

    return labels;
  }

  String _returnReference(ReturnFlowState flowState) {
    final completed = flowState.completedReceipt?.receiptNumber.trim() ?? '';
    if (completed.isNotEmpty) {
      return completed;
    }

    // Final return/receipt numbers are created only after completion (Step 10).
    return 'Generated after completion';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    final flowState = ref.watch(returnFlowProvider);
    final isExchange =
        flowState.selectedResolution == ReturnResolutionType.exchange;
    final exchangeState = ref.watch(returnExchangeFlowProvider);

    if (isExchange) {
      if (!PosPermissionAccess.canProcessExchange(granted)) {
        return const TenantAdminForbiddenScreen();
      }
      if (exchangeState.isForbidden) {
        return const TenantAdminForbiddenScreen();
      }
    } else if (!PosPermissionAccess.canProcessRefund(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final reviewState = ref.watch(returnReviewProvider);
    // Never treat Step 8 cached preview as authoritative on Step 9.
    final preview = reviewState.preview;
    final difference = isExchange && exchangeState.preview != null
        ? exchangeDifferenceFromPreview(
            differenceDirection: exchangeState.preview!.differenceDirection,
            differenceAmount: exchangeState.preview!.differenceAmount,
            currencyCode: exchangeState.preview!.currencyCode,
          )
        : null;
    final canComplete =
        ref.read(returnReviewProvider.notifier).canComplete(flowState);

    if (_isGuarding) {
      return const ColoredBox(
        color: TenantAdminColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final hasPrerequisites = flowState.selectedSale != null &&
        flowState.selectedReturnLines.isNotEmpty &&
        flowState.selectedReasonCode != null &&
        flowState.selectedResolution != null &&
        (!isExchange || exchangeState.replacementPersisted);

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
                  currentStep: ReturnFlowSteps.settlement,
                  selectedBranch: flowState.selectedResolution,
                ),
                const SizedBox(height: TenantAdminSpacing.xl),
                const ReturnExchangeReviewHeader(),
                const SizedBox(height: TenantAdminSpacing.lg),
                Expanded(
                  child: !hasPrerequisites
                      ? const TenantAdminEmptyState(
                          title: 'Return flow incomplete',
                          message:
                              'Complete earlier return steps before reviewing the receipt preview.',
                          icon: Icons.receipt_long_outlined,
                        )
                      : reviewState.isLoadingPreview
                          ? const Center(child: CircularProgressIndicator())
                          : reviewState.previewErrorMessage != null
                              ? TenantAdminErrorState(
                                  title: 'Unable to load preview',
                                  message: reviewState.previewErrorMessage!,
                                  onRetry: () => ref
                                      .read(returnReviewProvider.notifier)
                                      .loadPreview(),
                                )
                              : preview == null
                                  ? const TenantAdminEmptyState(
                                      title: 'Preview unavailable',
                                      message:
                                          'Unable to load latest exchange summary',
                                      icon: Icons.receipt_outlined,
                                    )
                                  : SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          ReturnReferenceDetailsCard(
                                            returnReference:
                                                _returnReference(flowState),
                                            customerName:
                                                preview.customerName.isNotEmpty
                                                    ? preview.customerName
                                                    : (flowState.selectedSale
                                                            ?.customerName ??
                                                        ''),
                                            processedBy:
                                                session?.userDisplayName ?? '',
                                          ),
                                          const SizedBox(
                                            height: TenantAdminSpacing.lg,
                                          ),
                                          if (twoColumn)
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 7,
                                                  child:
                                                      ReturnReviewItemsSection(
                                                    items: preview.items,
                                                    currencyCode:
                                                        preview.currency,
                                                    invoiceNo:
                                                        preview.invoiceNo,
                                                    conditionBySaleLineId:
                                                        _conditionLabels(
                                                      flowState,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: TenantAdminSpacing.xl,
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: _SummaryColumn(
                                                    flowState: flowState,
                                                    preview: preview,
                                                    isExchange: isExchange,
                                                    difference: difference,
                                                    exchangePreview:
                                                        exchangeState.preview,
                                                  ),
                                                ),
                                              ],
                                            )
                                          else ...[
                                            ReturnReviewItemsSection(
                                              items: preview.items,
                                              currencyCode: preview.currency,
                                              invoiceNo: preview.invoiceNo,
                                              conditionBySaleLineId:
                                                  _conditionLabels(flowState),
                                            ),
                                            const SizedBox(
                                              height: TenantAdminSpacing.lg,
                                            ),
                                            _SummaryColumn(
                                              flowState: flowState,
                                              preview: preview,
                                              isExchange: isExchange,
                                              difference: difference,
                                              exchangePreview:
                                                  exchangeState.preview,
                                            ),
                                          ],
                                          if (reviewState
                                                  .completionErrorMessage !=
                                              null) ...[
                                            const SizedBox(
                                              height: TenantAdminSpacing.lg,
                                            ),
                                            Text(
                                              reviewState
                                                  .completionErrorMessage!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: TenantAdminColors
                                                        .danger,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                ReturnExchangeReviewActionFooter(
                  canComplete: canComplete,
                  isSubmitting: reviewState.isCompleting,
                  completeLabel:
                      isExchange ? 'Complete Exchange' : 'Complete Return',
                  onBack: _goBack,
                  onComplete: _completeReturn,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _goBack() {
    final flowState = ref.read(returnFlowProvider);
    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.branchAction);
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (flowState.selectedResolution == ReturnResolutionType.refund) {
      context.go('/pos/returns-refunds/refund-details');
      return;
    }
    context.go('/pos/returns-refunds/exchange');
  }

  Future<void> _completeReturn() async {
    final receipt =
        await ref.read(returnReviewProvider.notifier).completeReturn();
    if (!mounted || receipt == null) {
      return;
    }

    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.receipt);
    await context.push(
      '/pos/returns-refunds/receipt?returnId=${Uri.encodeComponent(receipt.returnId)}',
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.flowState,
    required this.preview,
    required this.isExchange,
    required this.difference,
    this.exchangePreview,
  });

  final ReturnFlowState flowState;
  final ReturnCreditPreview preview;
  final bool isExchange;
  final ExchangeDifferencePresentation? difference;
  final ReturnExchangePreview? exchangePreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReturnFinancialSummaryCard(
          resolution: flowState.selectedResolution,
          preview: preview,
          replacement: flowState.selectedReplacement,
          difference: difference,
          exchangePreview: exchangePreview,
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        if (isExchange)
          ExchangeSettlementDetailsCard(
            currencyCode: exchangePreview?.currencyCode ?? preview.currency,
            returnItemValue: exchangePreview?.returnItemValue ??
                preview.calculation.netCreditAmount,
            replacementValue: exchangePreview?.replacementItemValue,
            difference: difference,
            replacement: flowState.selectedReplacement,
          )
        else
          RefundSettlementDetailsCard(
            preview: preview,
            refundMethod: flowState.selectedRefundMethod,
            settlementMethodCode: flowState.selectedSettlementMethodCode,
            transactionReference:
                flowState.completedReceipt?.returnId.isNotEmpty == true
                    ? flowState.completedReceipt!.returnId
                    : flowState.completedReceipt?.receiptNumber,
          ),
        const SizedBox(height: TenantAdminSpacing.lg),
        SettlementInformationBanner(
          message: settlementInformationMessage(
            flowState: flowState,
            preview: preview,
          ),
        ),
      ],
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

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

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
              Text(
                '$tillLabel ${isOpen ? 'Open' : 'Closed'}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.xl),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TenantAdminColors.mutedText,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
