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
import '../providers/return_eligibility_provider.dart';
import '../providers/return_flow_provider.dart';
import '../widgets/return_select_items_summary_cards.dart';
import '../widgets/return_select_items_table.dart';
import '../widgets/return_select_items_toolbar.dart';
import '../widgets/return_stepper.dart';

class PosReturnEligibilityScreen extends ConsumerStatefulWidget {
  const PosReturnEligibilityScreen({super.key});

  @override
  ConsumerState<PosReturnEligibilityScreen> createState() =>
      _PosReturnEligibilityScreenState();
}

class _PosReturnEligibilityScreenState
    extends ConsumerState<PosReturnEligibilityScreen> {
  final _searchController = TextEditingController();
  var _query = '';
  var _returnableOnly = false;

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

      final loadedSaleId =
          ref.read(returnEligibilityProvider).eligibility?.saleId;
      if (loadedSaleId != sale.saleId) {
        ref.read(returnEligibilityProvider.notifier).load(sale.saleId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canViewReturns(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final canMutate = PosPermissionAccess.canViewReturns(granted) &&
        PosPermissionAccess.canCreateReturn(granted);
    final selectedSale = ref.watch(returnFlowProvider).selectedSale;
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
                const ReturnStepper(
                  currentStep: ReturnFlowSteps.eligibilityAndItems,
                ),
                const SizedBox(height: TenantAdminSpacing.xl),
                Expanded(
                  child: _Body(
                    selectedSaleMissing: selectedSale == null,
                    eligibility: eligibility,
                    eligibilityState: eligibilityState,
                    canMutate: canMutate,
                    query: _query,
                    returnableOnly: _returnableOnly,
                    searchController: _searchController,
                    onQueryChanged: (value) => setState(() => _query = value),
                    onToggleFilters: () => setState(
                      () => _returnableOnly = !_returnableOnly,
                    ),
                    onRetry: selectedSale == null
                        ? null
                        : () => ref
                            .read(returnEligibilityProvider.notifier)
                            .load(selectedSale.saleId),
                    onBack: _goBack,
                    onContinue: _continueToCheckEligibility,
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
    context.go('/pos/returns-refunds/summary');
  }

  void _continueToCheckEligibility() {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canViewReturns(granted) ||
        !PosPermissionAccess.canCreateReturn(granted)) {
      return;
    }

    final eligibilityState = ref.read(returnEligibilityProvider);
    final eligibility = eligibilityState.eligibility;
    if (eligibility == null || !eligibilityState.canContinueSelection) {
      return;
    }

    final selectedLines = eligibilityState.selectedItems.map((item) {
      final qty =
          eligibilityState.selectionFor(item.saleLineId)?.returnQty ?? 0;
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

    if (selectedLines.isEmpty) {
      return;
    }

    ref.read(returnFlowProvider.notifier)
      ..setSelectedReturnLines(selectedLines)
      ..setStep(ReturnFlowSteps.checkEligibility);

    context.push('/pos/returns-refunds/check-eligibility');
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.selectedSaleMissing,
    required this.eligibility,
    required this.eligibilityState,
    required this.canMutate,
    required this.query,
    required this.returnableOnly,
    required this.searchController,
    required this.onQueryChanged,
    required this.onToggleFilters,
    required this.onRetry,
    required this.onBack,
    required this.onContinue,
  });

  final bool selectedSaleMissing;
  final ReturnSaleEligibility? eligibility;
  final ReturnEligibilityState eligibilityState;
  final bool canMutate;
  final String query;
  final bool returnableOnly;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onToggleFilters;
  final VoidCallback? onRetry;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    if (selectedSaleMissing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            child: TenantAdminEmptyState(
              title: 'Original sale required',
              message:
                  'Go back and select an original sale before selecting items.',
              icon: Icons.receipt_long_outlined,
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

    if (eligibilityState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (eligibilityState.errorMessage != null) {
      return TenantAdminErrorState(
        title: 'Unable to load purchased items',
        message: eligibilityState.errorMessage!,
        onRetry: onRetry,
      );
    }

    final data = eligibility;
    if (data == null) {
      return const TenantAdminEmptyState(
        title: 'No sale items',
        message: 'Purchased-item details are unavailable for this sale.',
        icon: Icons.inventory_2_outlined,
      );
    }

    final sale = data;
    final flowSale = eligibilityState.eligibility;
    final visibleItems = filterReturnEligibilityItems(
      sale.items,
      query: query,
      returnableOnly: returnableOnly,
    );
    final selectedSale = flowSale == null ? null : sale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 860;
        final content = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PageTitle(width: constraints.maxWidth),
              const SizedBox(height: TenantAdminSpacing.md),
              if (useTwoColumns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 64,
                      child: _ItemsColumn(
                        eligibility: sale,
                        items: visibleItems,
                        canMutate: canMutate,
                        query: query,
                        returnableOnly: returnableOnly,
                        searchController: searchController,
                        onQueryChanged: onQueryChanged,
                        onToggleFilters: onToggleFilters,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.xl),
                    Expanded(
                      flex: 36,
                      child: _SummaryColumn(
                        eligibility: sale,
                        state: eligibilityState,
                      ),
                    ),
                  ],
                )
              else ...[
                _ItemsColumn(
                  eligibility: sale,
                  items: visibleItems,
                  canMutate: canMutate,
                  query: query,
                  returnableOnly: returnableOnly,
                  searchController: searchController,
                  onQueryChanged: onQueryChanged,
                  onToggleFilters: onToggleFilters,
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                _SummaryColumn(
                  eligibility: sale,
                  state: eligibilityState,
                ),
              ],
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: content),
            const SizedBox(height: TenantAdminSpacing.lg),
            _ActionFooter(
              canContinue: canMutate &&
                  selectedSale != null &&
                  eligibilityState.canContinueSelection,
              onBack: onBack,
              onContinue: onContinue,
            ),
          ],
        );
      },
    );
  }
}

class _ItemsColumn extends StatelessWidget {
  const _ItemsColumn({
    required this.eligibility,
    required this.items,
    required this.canMutate,
    required this.query,
    required this.returnableOnly,
    required this.searchController,
    required this.onQueryChanged,
    required this.onToggleFilters,
  });

  final ReturnSaleEligibility eligibility;
  final List<ReturnSaleLineEligibility> items;
  final bool canMutate;
  final String query;
  final bool returnableOnly;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onToggleFilters;

  @override
  Widget build(BuildContext context) {
    final emptyMessage = query.trim().isNotEmpty || returnableOnly
        ? 'No purchased items match the current search or filter.'
        : 'No purchased items were found for this original sale.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReturnSelectItemsToolbar(
          controller: searchController,
          onChanged: onQueryChanged,
          filtersActive: returnableOnly,
          onToggleFilters: onToggleFilters,
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        ReturnSelectItemsTable(
          items: items,
          currency: eligibility.currency,
          emptyMessage: emptyMessage,
          canMutate: canMutate,
        ),
      ],
    );
  }
}

class _SummaryColumn extends ConsumerWidget {
  const _SummaryColumn({
    required this.eligibility,
    required this.state,
  });

  final ReturnSaleEligibility eligibility;
  final ReturnEligibilityState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sale = ref.watch(returnFlowProvider).selectedSale;
    if (sale == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReturnSelectOriginalSaleSummaryCard(
          sale: sale,
          eligibility: eligibility,
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        ReturnSelectionSummaryCard(
          selectedItemCount: state.selectedItemCount,
          totalReturnValue: state.estimatedReturnValue,
          currency: eligibility.currency,
        ),
      ],
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final compact = width < TenantAdminBreakpoints.tablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Items',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: TenantAdminColors.bodyText,
                fontSize: compact ? 20 : 21,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'Choose the items and quantities to include in the return or exchange.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TenantAdminColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
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
        final backButton = OutlinedButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          label: const Text('Back'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: TenantAdminColors.bodyText,
            side: const BorderSide(color: TenantAdminColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
          ),
        );
        final continueButton = PosPrimaryActionButton(
          label: 'Continue to Check Eligibility',
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
            SizedBox(width: 330, child: continueButton),
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
