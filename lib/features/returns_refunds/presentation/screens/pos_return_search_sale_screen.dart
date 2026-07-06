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
import '../providers/return_search_provider.dart';
import '../widgets/return_continue_footer.dart';
import '../widgets/return_recent_search_chips.dart';
import '../widgets/return_sale_result_card.dart';
import '../widgets/return_sale_summary_card.dart';
import '../widgets/return_search_bar.dart';
import '../widgets/return_search_filter_tabs.dart';
import '../widgets/return_search_page_header.dart';
import '../widgets/return_stepper.dart';

class PosReturnSearchSaleScreen extends ConsumerStatefulWidget {
  const PosReturnSearchSaleScreen({super.key});

  @override
  ConsumerState<PosReturnSearchSaleScreen> createState() =>
      _PosReturnSearchSaleScreenState();
}

class _PosReturnSearchSaleScreenState
    extends ConsumerState<PosReturnSearchSaleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.searchSale);
      ref.read(returnSearchProvider.notifier).search();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canViewReturnsOrRefunds(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final searchState = ref.watch(returnSearchProvider);
    final selectedSale = searchState.selectedSale;

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
                  ReturnSearchPageHeader(onBack: _goBack),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  const ReturnStepper(currentStep: ReturnFlowSteps.searchSale),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Expanded(
                    child: useSidePanel
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _SearchPanel(searchState: searchState),
                              ),
                              const SizedBox(width: TenantAdminSpacing.lg),
                              Expanded(
                                flex: 2,
                                child: ReturnSaleSummaryCard(sale: selectedSale),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _SearchPanel(searchState: searchState),
                              ),
                              const SizedBox(height: TenantAdminSpacing.lg),
                              ReturnSaleSummaryCard(sale: selectedSale),
                            ],
                          ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  ReturnContinueFooter(
                    canContinue: searchState.canContinue,
                    continueLabel: 'Continue to Eligibility',
                    onCancel: _goBack,
                    onContinue: _continueToEligibility,
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
    context.go('/pos/home');
  }

  void _continueToEligibility() {
    final sale = ref.read(returnSearchProvider).selectedSale;
    if (sale == null) {
      return;
    }

    ref.read(returnFlowProvider.notifier)
      ..selectSale(sale)
      ..setStep(ReturnFlowSteps.eligibilityAndItems);

    context.push('/pos/returns-refunds/eligibility');
  }
}

class _SearchPanel extends ConsumerWidget {
  const _SearchPanel({required this.searchState});

  final ReturnSearchState searchState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(returnSearchProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReturnSearchBar(
          query: searchState.query,
          showFilters: searchState.showFilters,
          onQueryChanged: (value) {
            notifier.setQuery(value);
            notifier.search();
          },
          onSearch: notifier.search,
          onToggleFilters: notifier.toggleFilters,
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        ReturnSearchFilterTabs(
          selectedTab: searchState.tab,
          onTabSelected: (tab) {
            notifier.setTab(tab);
            notifier.search();
          },
        ),
        if (searchState.showFilters) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            'Advanced filters will be available in a later release.',
            style: TenantAdminTextStyles.muted(context),
          ),
        ],
        const SizedBox(height: TenantAdminSpacing.lg),
        ReturnRecentSearchChips(
          items: searchState.recentSearches,
          onSelected: (value) {
            notifier.applyRecentSearch(value);
            notifier.search();
          },
          onRemoved: notifier.removeRecentSearch,
          onClearAll: notifier.clearRecentSearches,
        ),
        if (searchState.recentSearches.isNotEmpty)
          const SizedBox(height: TenantAdminSpacing.lg),
        Expanded(child: _SearchResults(searchState: searchState)),
        const SizedBox(height: TenantAdminSpacing.md),
        const _SearchInfoBanner(),
      ],
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.searchState});

  final ReturnSearchState searchState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.errorMessage != null) {
      return TenantAdminErrorState(
        title: 'Search failed',
        message: searchState.errorMessage!,
        onRetry: ref.read(returnSearchProvider.notifier).search,
      );
    }

    if (searchState.results.isEmpty) {
      return const TenantAdminEmptyState(
        title: 'No sales found',
        message:
            'Try a different invoice number, mobile number, or customer name.',
        icon: Icons.receipt_long_outlined,
      );
    }

    return ListView.separated(
      itemCount: searchState.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: TenantAdminSpacing.md),
      itemBuilder: (context, index) {
        final sale = searchState.results[index];
        return ReturnSaleResultCard(
          sale: sale,
          selected: searchState.selectedSaleId == sale.saleId,
          onSelected: () =>
              ref.read(returnSearchProvider.notifier).selectSale(sale.saleId),
        );
      },
    );
  }
}

class _SearchInfoBanner extends StatelessWidget {
  const _SearchInfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.secondary,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: TenantAdminColors.info.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: TenantAdminColors.info,
            size: 20,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              'A valid original sale is required to continue the return or refund process.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
