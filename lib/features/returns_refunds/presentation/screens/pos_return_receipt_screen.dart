import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../providers/return_flow_provider.dart';
import '../providers/return_success_display.dart';
import '../providers/return_success_provider.dart';
import '../widgets/receipt_success/completed_items_summary_card.dart';
import '../widgets/receipt_success/completion_details_card.dart';
import '../widgets/receipt_success/completion_information_banner.dart';
import '../widgets/receipt_success/invalid_completion_state.dart';
import '../widgets/receipt_success/return_exchange_success_hero.dart';
import '../widgets/receipt_success/success_page_actions.dart';
import '../widgets/return_stepper.dart';

class PosReturnReceiptScreen extends ConsumerStatefulWidget {
  const PosReturnReceiptScreen({super.key});

  @override
  ConsumerState<PosReturnReceiptScreen> createState() =>
      _PosReturnReceiptScreenState();
}

class _PosReturnReceiptScreenState
    extends ConsumerState<PosReturnReceiptScreen> {
  String? _routeReturnId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.receipt);
      final queryReturnId =
          GoRouterState.of(context).uri.queryParameters['returnId'];
      _routeReturnId = queryReturnId?.trim();
      ref.read(returnSuccessProvider.notifier).loadCompletion(
            returnId: _routeReturnId,
          );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final queryReturnId =
        GoRouterState.of(context).uri.queryParameters['returnId']?.trim();
    if (queryReturnId != null &&
        queryReturnId.isNotEmpty &&
        queryReturnId != _routeReturnId) {
      _routeReturnId = queryReturnId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref.read(returnSuccessProvider.notifier).loadCompletion(
              returnId: _routeReturnId,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canAccessReturnSuccessRoute(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final flowState = ref.watch(returnFlowProvider);
    final successState = ref.watch(returnSuccessProvider);
    // Completion GET is the only success authority — never fall back to memory.
    final receipt = successState.loadStatus == ReturnSuccessLoadStatus.loaded
        ? successState.receipt
        : null;
    final display =
        receipt == null ? null : buildReturnSuccessDisplayFromReceipt(receipt);

    if (successState.loadStatus == ReturnSuccessLoadStatus.permissionDenied ||
        (receipt != null && !_canViewBranch(granted, receipt.isExchange))) {
      return const TenantAdminForbiddenScreen();
    }

    final canPrint = PosPermissionAccess.canPrintReceipts(granted) &&
        (display?.canPrint ?? false) &&
        successState.printStatus != ReturnSuccessPrintStatus.inProgress;
    final canStartNew = PosPermissionAccess.canStartNewReturn(granted);
    final canGoHome = PosPermissionAccess.canViewHome(granted);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (canGoHome) {
          _backToHome();
        }
      },
      child: ColoredBox(
        color: TenantAdminColors.background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding =
                constraints.maxWidth >= TenantAdminBreakpoints.tablet
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
                    currentStep: ReturnFlowSteps.receipt,
                    selectedBranch: flowState.selectedResolution,
                  ),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  Expanded(
                    child: _buildBody(
                      context: context,
                      successState: successState,
                      display: display,
                      twoColumn: twoColumn,
                      canGoHome: canGoHome,
                    ),
                  ),
                  if (display != null) ...[
                    const SizedBox(height: TenantAdminSpacing.lg),
                    SuccessPageActions(
                      isPrinting: successState.printStatus ==
                          ReturnSuccessPrintStatus.inProgress,
                      isNavigating: successState.isNavigating,
                      printEnabled:
                          canPrint || successState.auditPendingAfterPrint,
                      startNewReturnEnabled: canStartNew,
                      backToHomeEnabled: canGoHome,
                      hasBeenPrinted: display.hasBeenPrinted,
                      auditPending: successState.auditPendingAfterPrint,
                      onPrintReceipt: _printReceipt,
                      onRetryAudit: _retryAudit,
                      onStartNewReturn: _startNewReturn,
                      onBackToHome: _backToHome,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required ReturnSuccessState successState,
    required ReturnSuccessDisplay? display,
    required bool twoColumn,
    required bool canGoHome,
  }) {
    if (successState.loadStatus == ReturnSuccessLoadStatus.loading ||
        successState.loadStatus == ReturnSuccessLoadStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }

    if (display == null) {
      return InvalidCompletionState(
        title: _invalidTitle(successState.loadStatus),
        message: successState.loadMessage ??
            'This success page can only be shown after a confirmed return or exchange completion.',
        showBackToReview: false,
        showRetry: successState.loadStatus == ReturnSuccessLoadStatus.failed ||
            successState.loadStatus == ReturnSuccessLoadStatus.notReady ||
            successState.loadStatus == ReturnSuccessLoadStatus.notFound,
        onRetry: _retryLoad,
        onBackToHome: canGoHome
            ? _backToHome
            : () {
                context.go('/pos');
              },
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (twoColumn)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      ReturnExchangeSuccessHero(
                        heading: display.heading,
                        supportingMessage: display.supportingMessage,
                      ),
                      const SizedBox(height: TenantAdminSpacing.xl),
                      CompletionDetailsCard(display: display),
                      if (display.settlementMessage != null) ...[
                        const SizedBox(height: TenantAdminSpacing.lg),
                        CompletionInformationBanner(
                          message: display.settlementMessage!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.xl),
                Expanded(
                  flex: 4,
                  child: CompletedItemsSummaryCard(
                    items: display.items,
                    currencyCode: display.currencyCode,
                    totalItems: display.itemCount,
                  ),
                ),
              ],
            )
          else ...[
            ReturnExchangeSuccessHero(
              heading: display.heading,
              supportingMessage: display.supportingMessage,
            ),
            const SizedBox(height: TenantAdminSpacing.xl),
            CompletionDetailsCard(display: display),
            if (display.settlementMessage != null) ...[
              const SizedBox(height: TenantAdminSpacing.lg),
              CompletionInformationBanner(
                message: display.settlementMessage!,
              ),
            ],
            const SizedBox(height: TenantAdminSpacing.lg),
            CompletedItemsSummaryCard(
              items: display.items,
              currencyCode: display.currencyCode,
              totalItems: display.itemCount,
            ),
          ],
          if (successState.printMessage != null) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              successState.printMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _invalidTitle(ReturnSuccessLoadStatus status) {
    switch (status) {
      case ReturnSuccessLoadStatus.notFound:
        return 'Receipt not found';
      case ReturnSuccessLoadStatus.exchangeIncomplete:
        return 'Exchange incomplete';
      case ReturnSuccessLoadStatus.notReady:
        return 'Completion pending';
      case ReturnSuccessLoadStatus.permissionDenied:
        return 'Permission Denied';
      default:
        return 'Completion details unavailable';
    }
  }

  bool _canViewBranch(Set<String> granted, bool isExchange) {
    return isExchange
        ? PosPermissionAccess.canViewExchangeSuccess(granted)
        : PosPermissionAccess.canViewRefundSuccess(granted);
  }

  Future<void> _printReceipt() async {
    final granted =
        ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canPrintReceipts(granted)) {
      return;
    }
    await ref.read(returnSuccessProvider.notifier).requestPrint();
  }

  Future<void> _retryAudit() async {
    await ref.read(returnSuccessProvider.notifier).retryAuditOnly();
  }

  void _retryLoad() {
    ref.read(returnSuccessProvider.notifier).loadCompletion(
          returnId: _routeReturnId,
        );
  }

  void _startNewReturn() {
    final granted =
        ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canStartNewReturn(granted)) {
      return;
    }
    final notifier = ref.read(returnSuccessProvider.notifier);
    if (!notifier.beginNavigation()) {
      return;
    }
    notifier.resetReturnExchangeDraft();
    context.go('/pos/returns-refunds');
  }

  void _backToHome() {
    final granted =
        ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canViewHome(granted)) {
      return;
    }
    final notifier = ref.read(returnSuccessProvider.notifier);
    if (!notifier.beginNavigation()) {
      return;
    }
    notifier.resetReturnExchangeDraft();
    context.go('/pos/home');
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
