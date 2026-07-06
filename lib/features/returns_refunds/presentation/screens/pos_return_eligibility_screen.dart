import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../providers/return_eligibility_provider.dart';
import '../providers/return_flow_provider.dart';
import '../widgets/return_continue_footer.dart';
import '../widgets/return_eligibility_summary_card.dart';
import '../widgets/return_policy_checks_card.dart';
import '../widgets/return_sale_context_bar.dart';
import '../widgets/return_sold_items_section.dart';
import '../widgets/return_stepper.dart';

class PosReturnEligibilityScreen extends ConsumerStatefulWidget {
  const PosReturnEligibilityScreen({super.key});

  @override
  ConsumerState<PosReturnEligibilityScreen> createState() =>
      _PosReturnEligibilityScreenState();
}

class _PosReturnEligibilityScreenState
    extends ConsumerState<PosReturnEligibilityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(returnFlowProvider.notifier).setStep(
            ReturnFlowSteps.eligibilityAndItems,
          );

      final sale = ref.read(returnFlowProvider).selectedSale;
      if (sale == null) {
        return;
      }

      ref.read(returnEligibilityProvider.notifier).load(sale.saleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canViewReturnsOrRefunds(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final selectedSale = ref.watch(returnFlowProvider).selectedSale;
    final eligibilityState = ref.watch(returnEligibilityProvider);
    final eligibility = eligibilityState.eligibility;

    if (selectedSale == null) {
      return ColoredBox(
        color: TenantAdminColors.background,
        child: Padding(
          padding:
              TenantAdminInsets.pageForWidth(MediaQuery.sizeOf(context).width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onBack: _goBack),
              const SizedBox(height: TenantAdminSpacing.lg),
              const ReturnStepper(
                currentStep: ReturnFlowSteps.eligibilityAndItems,
              ),
              const Expanded(
                child: TenantAdminEmptyState(
                  title: 'Original sale required',
                  message:
                      'Go back and select an original sale before checking eligibility.',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              ReturnContinueFooter(
                canContinue: false,
                cancelLabel: 'Back',
                continueLabel: 'Continue to Return Reason',
                onCancel: _goBack,
                onContinue: () {},
              ),
            ],
          ),
        ),
      );
    }

    return ColoredBox(
      color: TenantAdminColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);
          final useSidePanel =
              constraints.maxWidth >= TenantAdminBreakpoints.tablet;

          return Padding(
            padding: padding,
            child: SizedBox.expand(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(onBack: _goBack),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  const ReturnStepper(
                    currentStep: ReturnFlowSteps.eligibilityAndItems,
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  if (eligibilityState.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (eligibilityState.errorMessage != null)
                    Expanded(
                      child: TenantAdminErrorState(
                        title: 'Unable to load eligibility',
                        message: eligibilityState.errorMessage!,
                        onRetry: () => ref
                            .read(returnEligibilityProvider.notifier)
                            .load(selectedSale.saleId),
                      ),
                    )
                  else if (eligibility == null)
                    const Expanded(
                      child: TenantAdminEmptyState(
                        title: 'No eligibility data',
                        message: 'Sale eligibility details are unavailable.',
                        icon: Icons.fact_check_outlined,
                      ),
                    )
                  else ...[
                    ReturnSaleContextBar(eligibility: eligibility),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    Expanded(
                      child: useSidePanel
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  flex: 3,
                                  child: SingleChildScrollView(
                                    child: ReturnSoldItemsSection(),
                                  ),
                                ),
                                const SizedBox(width: TenantAdminSpacing.lg),
                                Expanded(
                                  flex: 2,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ReturnPolicyChecksCard(
                                          checks: eligibility.policyChecks,
                                        ),
                                        const SizedBox(
                                          height: TenantAdminSpacing.lg,
                                        ),
                                        const ReturnEligibilitySummaryCard(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const ReturnSoldItemsSection(),
                                  const SizedBox(height: TenantAdminSpacing.lg),
                                  ReturnPolicyChecksCard(
                                    checks: eligibility.policyChecks,
                                  ),
                                  const SizedBox(height: TenantAdminSpacing.lg),
                                  const ReturnEligibilitySummaryCard(),
                                ],
                              ),
                            ),
                    ),
                  ],
                  const SizedBox(height: TenantAdminSpacing.lg),
                  ReturnContinueFooter(
                    canContinue: eligibilityState.canContinue,
                    cancelLabel: 'Back',
                    continueLabel: 'Continue to Return Reason',
                    onCancel: _goBack,
                    onContinue: _continueToReturnReason,
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
    context.go('/pos/returns-refunds');
  }

  void _continueToReturnReason() {
    final eligibilityState = ref.read(returnEligibilityProvider);
    final eligibility = eligibilityState.eligibility;
    if (eligibility == null || !eligibilityState.canContinue) {
      return;
    }

    final selectedLines = eligibilityState.selectedItems.map((item) {
      final qty = eligibilityState.selectionFor(item.saleLineId)?.returnQty ?? 0;
      return ReturnSelectedReturnLine(
        saleLineId: item.saleLineId,
        name: item.name,
        unitPrice: item.unitPrice,
        returnQty: qty,
        lineTotal: item.unitPrice * qty,
        sku: item.sku,
        imageStorageKey: item.imageStorageKey,
      );
    }).toList(growable: false);

    ref.read(returnFlowProvider.notifier)
      ..setSelectedReturnLines(selectedLines)
      ..setStep(ReturnFlowSteps.returnReason);

    context.push('/pos/returns-refunds/return-reason');
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
          tooltip: 'Back to Search Sale',
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
                'Eligibility & Select Items',
                style: TenantAdminTextStyles.pageTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                'Review return eligibility and choose the items to return.',
                style: TenantAdminTextStyles.muted(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
