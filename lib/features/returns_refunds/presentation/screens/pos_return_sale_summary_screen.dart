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
import '../../domain/entities/return_sale_summary.dart';
import '../navigation/returns_route_guard.dart';
import '../providers/return_eligibility_provider.dart';
import '../providers/return_flow_provider.dart';
import '../widgets/return_continue_footer.dart';
import '../widgets/return_original_sale_summary_cards.dart';
import '../widgets/return_purchased_items_section.dart';
import '../widgets/return_stepper.dart';

class PosReturnSaleSummaryScreen extends ConsumerStatefulWidget {
  const PosReturnSaleSummaryScreen({super.key});

  @override
  ConsumerState<PosReturnSaleSummaryScreen> createState() =>
      _PosReturnSaleSummaryScreenState();
}

class _PosReturnSaleSummaryScreenState
    extends ConsumerState<PosReturnSaleSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final flow = ref.read(returnFlowProvider);
      if (!ReturnsRouteGuard.hasSelectedSaleContext(flow)) {
        if (!mounted) {
          return;
        }
        context.go('/pos/returns-refunds');
        return;
      }

      ref
          .read(returnFlowProvider.notifier)
          .setStep(ReturnFlowSteps.saleSummary);
      final sale = flow.selectedSale;
      if (sale != null) {
        ref.read(returnEligibilityProvider.notifier).load(sale.saleId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canViewReturns(granted) ||
        !PosPermissionAccess.canCreateReturn(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final flow = ref.watch(returnFlowProvider);
    if (!ReturnsRouteGuard.hasSelectedSaleContext(flow)) {
      return const ColoredBox(
        color: TenantAdminColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final sale = flow.selectedSale;
    final eligibilityState = ref.watch(returnEligibilityProvider);
    final eligibility = eligibilityState.eligibility;

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
                const ReturnStepper(currentStep: ReturnFlowSteps.saleSummary),
                const SizedBox(height: TenantAdminSpacing.lg),
                const _PageTitle(),
                const SizedBox(height: TenantAdminSpacing.md),
                Expanded(
                  child: _Body(
                    sale: sale,
                    eligibility: eligibility,
                    isLoading: eligibilityState.isLoading,
                    errorMessage: eligibilityState.errorMessage,
                    onRetry: sale == null
                        ? null
                        : () => ref
                            .read(returnEligibilityProvider.notifier)
                            .load(sale.saleId),
                    onBack: _goBack,
                    onContinue: _continueToSelectItems,
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
    context.go('/pos/returns-refunds');
  }

  void _continueToSelectItems() {
    ref
        .read(returnFlowProvider.notifier)
        .setStep(ReturnFlowSteps.eligibilityAndItems);
    context.push('/pos/returns-refunds/eligibility');
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.sale,
    required this.eligibility,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onBack,
    required this.onContinue,
  });

  final ReturnSaleSummary? sale;
  final ReturnSaleEligibility? eligibility;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    if (sale == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            child: TenantAdminEmptyState(
              title: 'Original sale required',
              message:
                  'Go back and select an original sale before viewing the summary.',
              icon: Icons.receipt_long_outlined,
            ),
          ),
          ReturnContinueFooter(
            canContinue: false,
            cancelLabel: 'Back',
            onCancel: onBack,
            onContinue: () {},
          ),
        ],
      );
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return TenantAdminErrorState(
        title: 'Unable to load original sale',
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    if (eligibility == null) {
      return const TenantAdminEmptyState(
        title: 'No sale details',
        message: 'Original sale details are unavailable.',
        icon: Icons.receipt_long_outlined,
      );
    }

    final selectedSale = sale!;
    final saleDetails = eligibility!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 760;
        final content = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (useTwoColumns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ReturnSaleDetailsCard(
                        sale: selectedSale,
                        eligibility: saleDetails,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.lg),
                    Expanded(
                      child: ReturnSaleFinancialSummaryCard(
                        sale: selectedSale,
                        eligibility: saleDetails,
                      ),
                    ),
                  ],
                )
              else ...[
                ReturnSaleDetailsCard(
                  sale: selectedSale,
                  eligibility: saleDetails,
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                ReturnSaleFinancialSummaryCard(
                  sale: selectedSale,
                  eligibility: saleDetails,
                ),
              ],
              const SizedBox(height: TenantAdminSpacing.lg),
              ReturnPurchasedItemsSection(
                items: saleDetails.items,
                currency: saleDetails.currency,
              ),
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: content),
            const SizedBox(height: TenantAdminSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(color: TenantAdminColors.border),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(
                  child: PosPrimaryActionButton(
                    label: 'Continue',
                    onPressed: onContinue,
                    trailingIcon: Icons.arrow_forward_rounded,
                    compact: true,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Original Sale Summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'Review the original sale details and purchased items.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TenantAdminColors.primary,
                fontWeight: FontWeight.w600,
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
