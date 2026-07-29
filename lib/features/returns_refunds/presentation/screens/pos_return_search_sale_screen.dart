import 'package:flutter/material.dart';
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../../domain/entities/return_sale_summary.dart';
import '../navigation/returns_route_guard.dart';
import '../providers/return_flow_provider.dart';
import '../providers/return_search_provider.dart';
import '../widgets/return_continue_footer.dart';
import '../widgets/return_recent_search_chips.dart';
import '../widgets/return_sale_result_card.dart';
import '../widgets/return_sale_summary_card.dart';
import '../widgets/return_search_bar.dart';
import '../widgets/return_search_filter_tabs.dart';
import '../widgets/return_search_filters_panel.dart';
import '../widgets/return_search_page_header.dart';
import '../widgets/return_search_pagination.dart';
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
      ref.read(returnSearchProvider.notifier).search(page: 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canViewReturns(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final searchState = ref.watch(returnSearchProvider);
    if (searchState.isForbidden) {
      return const TenantAdminForbiddenScreen();
    }

    final selectedSale = searchState.selectedSale;
    final canContinue = ReturnsRouteGuard.canContinueFromSearch(
      granted: granted,
      hasValidSelection: searchState.hasValidSelection,
      isLoading: searchState.isLoading,
    );

    return ColoredBox(
      color: TenantAdminColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth >= TenantAdminBreakpoints.tablet
              ? const EdgeInsets.fromLTRB(30, 46, 30, 28)
              : TenantAdminInsets.pageForWidth(constraints.maxWidth);
          final useSidePanel =
              constraints.maxWidth >= TenantAdminBreakpoints.tablet;

          return Padding(
            padding: padding,
            child: useSidePanel
                ? _DesktopSearchLayout(
                    searchState: searchState,
                    selectedSale: selectedSale,
                    canContinue: canContinue,
                    onCancel: _goBack,
                    onContinue: _continueToEligibility,
                  )
                : _MobileSearchLayout(
                    searchState: searchState,
                    selectedSale: selectedSale,
                    canContinue: canContinue,
                    onCancel: _goBack,
                    onContinue: _continueToEligibility,
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
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    final searchState = ref.read(returnSearchProvider);
    if (!ReturnsRouteGuard.canContinueFromSearch(
      granted: granted,
      hasValidSelection: searchState.hasValidSelection,
      isLoading: searchState.isLoading,
    )) {
      return;
    }

    final sale = searchState.selectedSale;
    if (sale == null) {
      return;
    }

    ref.read(returnFlowProvider.notifier)
      ..selectSale(sale)
      ..setStep(ReturnFlowSteps.saleSummary);

    context.push('/pos/returns-refunds/summary');
  }
}

class _DesktopSearchLayout extends StatelessWidget {
  const _DesktopSearchLayout({
    required this.searchState,
    required this.selectedSale,
    required this.canContinue,
    required this.onCancel,
    required this.onContinue,
  });

  final ReturnSearchState searchState;
  final ReturnSaleSummary? selectedSale;
  final bool canContinue;
  final VoidCallback onCancel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ReturnSearchPageHeader(),
          const SizedBox(height: 26),
          const ReturnStepper(currentStep: ReturnFlowSteps.searchSale),
          const SizedBox(height: 30),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gap = constraints.maxWidth >= 1020 ? 48.0 : 28.0;
                final rightWidth = constraints.maxWidth >= 1020 ? 370.0 : 340.0;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SearchPanel(
                        searchState: searchState,
                        fillResults: true,
                      ),
                    ),
                    SizedBox(width: gap),
                    SizedBox(
                      width: rightWidth,
                      child: _SummaryActionPanel(
                        sale: selectedSale,
                        canContinue: canContinue,
                        onCancel: onCancel,
                        onContinue: onContinue,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileSearchLayout extends StatelessWidget {
  const _MobileSearchLayout({
    required this.searchState,
    required this.selectedSale,
    required this.canContinue,
    required this.onCancel,
    required this.onContinue,
  });

  final ReturnSearchState searchState;
  final ReturnSaleSummary? selectedSale;
  final bool canContinue;
  final VoidCallback onCancel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ReturnSearchPageHeader(),
          const SizedBox(height: TenantAdminSpacing.lg),
          const ReturnStepper(currentStep: ReturnFlowSteps.searchSale),
          const SizedBox(height: TenantAdminSpacing.lg),
          _SearchPanel(searchState: searchState, fillResults: false),
          const SizedBox(height: TenantAdminSpacing.lg),
          ReturnSaleSummaryCard(sale: selectedSale, compact: true),
          const SizedBox(height: TenantAdminSpacing.lg),
          ReturnContinueFooter(
            canContinue: canContinue,
            continueLabel: 'Continue',
            onCancel: onCancel,
            onContinue: onContinue,
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends ConsumerWidget {
  const _SearchPanel({
    required this.searchState,
    required this.fillResults,
  });

  final ReturnSearchState searchState;
  final bool fillResults;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(returnSearchProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SearchSectionHeader(),
        const SizedBox(height: TenantAdminSpacing.lg),
        ReturnSearchBar(
          query: searchState.query,
          showFilters: searchState.showFilters,
          activeFilterCount: searchState.filters.activeCount,
          isLoading: searchState.isLoading,
          onQueryChanged: (value) {
            notifier.setQuery(value);
            notifier.search(page: 1);
          },
          onSearch: () => notifier.search(page: 1),
          onToggleFilters: notifier.toggleFilters,
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        ReturnSearchFilterTabs(
          selectedTab: searchState.tab,
          onTabSelected: (tab) {
            notifier.setTab(tab);
            notifier.search(page: 1);
          },
        ),
        if (searchState.showFilters) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          ReturnSearchFiltersPanel(
            filters: searchState.filters,
            paymentMethods: searchState.paymentMethods,
            isLoading: searchState.isLoading,
            onApply: notifier.applyFilters,
            onClear: notifier.clearFilters,
          ),
        ],
        const SizedBox(height: TenantAdminSpacing.lg),
        ReturnRecentSearchChips(
          items: searchState.recentSearches,
          onSelected: (value) {
            notifier.applyRecentSearch(value);
            notifier.search(page: 1);
          },
          onRemoved: notifier.removeRecentSearch,
          onClearAll: notifier.clearRecentSearches,
        ),
        if (searchState.recentSearches.isNotEmpty)
          const SizedBox(height: TenantAdminSpacing.lg),
        if (fillResults)
          Expanded(child: _SearchResults(searchState: searchState))
        else
          _SearchResults(searchState: searchState, shrinkWrap: true),
        if (fillResults) ...[
          const SizedBox(height: TenantAdminSpacing.lg),
          ReturnContinueGuidance(canContinue: searchState.hasValidSelection),
        ],
      ],
    );
  }
}

class _SearchSectionHeader extends StatelessWidget {
  const _SearchSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Original Sale',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: TenantAdminColors.bodyText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Text(
          'Find and select the original sale to begin the return or exchange.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TenantAdminColors.primary,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
        ),
      ],
    );
  }
}

class _SummaryActionPanel extends StatelessWidget {
  const _SummaryActionPanel({
    required this.sale,
    required this.canContinue,
    required this.onCancel,
    required this.onContinue,
  });

  final ReturnSaleSummary? sale;
  final bool canContinue;
  final VoidCallback onCancel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: ReturnSaleSummaryCard(sale: sale),
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 56),
            side: const BorderSide(color: TenantAdminColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        PosPrimaryActionButton(
          label: 'Continue',
          onPressed: canContinue ? onContinue : null,
          trailingIcon: Icons.arrow_forward_rounded,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.searchState,
    this.shrinkWrap = false,
  });

  final ReturnSearchState searchState;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.errorMessage != null) {
      final forbidden = searchState.errorMessage == 'Permission Denied';
      return TenantAdminErrorState(
        title: forbidden ? 'Permission Denied' : 'Search failed',
        message: searchState.errorMessage!,
        onRetry: () => ref.read(returnSearchProvider.notifier).search(page: 1),
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

    final pagination = ReturnSearchPagination(
      page: searchState.page,
      totalPages: searchState.totalPages,
      rangeStart: searchState.rangeStart,
      rangeEnd: searchState.rangeEnd,
      totalCount: searchState.totalCount,
      isLoading: searchState.isLoading,
      onPageChanged: (page) =>
          ref.read(returnSearchProvider.notifier).goToPage(page),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ResultsHeader(),
        const SizedBox(height: TenantAdminSpacing.sm),
        if (shrinkWrap)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: searchState.results.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: TenantAdminSpacing.md),
            itemBuilder: (context, index) => _resultCard(context, ref, index),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: searchState.results.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: TenantAdminSpacing.md),
              itemBuilder: (context, index) => _resultCard(context, ref, index),
            ),
          ),
        const SizedBox(height: TenantAdminSpacing.md),
        pagination,
      ],
    );
  }

  Widget _resultCard(BuildContext context, WidgetRef ref, int index) {
    final sale = searchState.results[index];
    return ReturnSaleResultCard(
      sale: sale,
      selected: searchState.selectedSaleId == sale.saleId,
      onSelected: () =>
          ref.read(returnSearchProvider.notifier).selectSale(sale.saleId),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Search Results',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w900,
          ),
    );
  }
}
