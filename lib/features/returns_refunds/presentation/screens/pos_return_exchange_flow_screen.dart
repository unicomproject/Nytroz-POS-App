import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/domain/entities/pos_catalog_models.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_states.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../domain/entities/exchange_difference_result.dart';
import '../../domain/entities/return_exchange.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../../domain/entities/return_resolution_type.dart';
import '../navigation/returns_route_guard.dart';
import '../providers/exchange_replacement_provider.dart';
import '../providers/return_exchange_flow_provider.dart';
import '../providers/return_flow_provider.dart';
import '../providers/return_resolution_provider.dart';
import '../widgets/exchange_replacement/exchange_summary_card.dart';
import '../widgets/exchange_replacement/exchange_variant_picker_sheet.dart';
import '../widgets/exchange_replacement/replacement_items_header.dart';
import '../widgets/exchange_replacement/replacement_items_search_toolbar.dart';
import '../widgets/exchange_replacement/replacement_products_section.dart';
import '../widgets/return_stepper.dart';
import '../widgets/returns_exchange_action_footer.dart';

class PosReturnExchangeFlowScreen extends ConsumerStatefulWidget {
  const PosReturnExchangeFlowScreen({super.key});

  @override
  ConsumerState<PosReturnExchangeFlowScreen> createState() =>
      _PosReturnExchangeFlowScreenState();
}

class _PosReturnExchangeFlowScreenState
    extends ConsumerState<PosReturnExchangeFlowScreen> {
  bool _isContinuing = false;
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
        !authoritative.exchangeAllowed ||
        authoritative.resolutionType != ReturnResolutionType.exchange) {
      if (mounted) context.go('/pos/returns-refunds/choose-option');
      return;
    }
    if (mounted) setState(() => _isGuarding = false);
    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.branchAction);
    ref.read(exchangeReplacementSearchProvider.notifier).loadProducts();
    ref.read(returnExchangeFlowProvider.notifier).hydrate();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canProcessExchange(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    if (_isGuarding) {
      return const ColoredBox(
        color: TenantAdminColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final flowState = ref.watch(returnFlowProvider);
    final searchState = ref.watch(exchangeReplacementSearchProvider);
    final exchangeState = ref.watch(returnExchangeFlowProvider);
    final preview = exchangeState.preview;
    final branchMismatch =
        !ReturnsRouteGuard.hasExchangeBranchContext(flowState);

    if (searchState.isForbidden || exchangeState.isForbidden) {
      return const TenantAdminForbiddenScreen();
    }

    final currencyCode = preview?.currencyCode ?? searchState.currencyCode;
    final returnItemValue = preview?.returnItemValue ?? 0;
    final newItemValue = preview?.replacementItemValue ?? 0;
    final difference = preview == null
        ? ExchangeDifferencePresentation(
            type: ExchangeDifferenceType.evenExchange,
            amount: 0,
            currencyCode: currencyCode,
          )
        : exchangeDifferenceFromPreview(
            differenceDirection: preview.differenceDirection,
            differenceAmount: preview.differenceAmount,
            currencyCode: preview.currencyCode.isNotEmpty
                ? preview.currencyCode
                : currencyCode,
          );
    final selectedKey = flowState.selectedReplacement?.selectionKey;

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
                const ReplacementItemsHeader(),
                const SizedBox(height: TenantAdminSpacing.lg),
                Expanded(
                  child: branchMismatch
                      ? const TenantAdminEmptyState(
                          title: 'Exchange branch not selected',
                          message:
                              'Return to Choose Option and select Exchange to continue this step.',
                          icon: Icons.alt_route_rounded,
                        )
                      : SingleChildScrollView(
                          child: twoColumn
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: _MainColumn(
                                        searchState: searchState,
                                        currencyCode: currencyCode,
                                        selectedKey: selectedKey,
                                        onProductSelected:
                                            _handleProductSelected,
                                      ),
                                    ),
                                    const SizedBox(
                                        width: TenantAdminSpacing.xl),
                                    Expanded(
                                      flex: 3,
                                      child: ExchangeSummaryCard(
                                        currencyCode: currencyCode,
                                        returnItemValue: returnItemValue,
                                        newItemValue: newItemValue,
                                        difference: difference,
                                        selection:
                                            flowState.selectedReplacement,
                                        isUpdatingQuantity:
                                            exchangeState.isSavingReplacement,
                                        onQuantityChanged: (qty) {
                                          ref
                                              .read(returnExchangeFlowProvider
                                                  .notifier)
                                              .updateReplacementQuantity(
                                                qty.toDouble(),
                                              );
                                        },
                                        policyMessages:
                                            preview?.policyMessages ?? const [],
                                        canProceed:
                                            preview?.canProceed ?? false,
                                        draftExpired:
                                            exchangeState.draftExpired,
                                        replacementTax:
                                            preview?.replacementTax ?? 0,
                                        replacementDiscount:
                                            preview?.replacementDiscount ?? 0,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _MainColumn(
                                      searchState: searchState,
                                      currencyCode: currencyCode,
                                      selectedKey: selectedKey,
                                      onProductSelected: _handleProductSelected,
                                    ),
                                    const SizedBox(
                                        height: TenantAdminSpacing.lg),
                                    ExchangeSummaryCard(
                                      currencyCode: currencyCode,
                                      returnItemValue: returnItemValue,
                                      newItemValue: newItemValue,
                                      difference: difference,
                                      selection: flowState.selectedReplacement,
                                      isUpdatingQuantity:
                                          exchangeState.isSavingReplacement,
                                      onQuantityChanged: (qty) {
                                        ref
                                            .read(returnExchangeFlowProvider
                                                .notifier)
                                            .updateReplacementQuantity(
                                              qty.toDouble(),
                                            );
                                      },
                                      policyMessages:
                                          preview?.policyMessages ?? const [],
                                      canProceed: preview?.canProceed ?? false,
                                      draftExpired: exchangeState.draftExpired,
                                      replacementTax:
                                          preview?.replacementTax ?? 0,
                                      replacementDiscount:
                                          preview?.replacementDiscount ?? 0,
                                    ),
                                  ],
                                ),
                        ),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                ReturnsExchangeActionFooter(
                  canContinue: exchangeState.canContinue && !_isContinuing,
                  isSubmitting: _isContinuing || exchangeState.isBusy,
                  continueLabel: 'Continue to Review',
                  onBack: _goBack,
                  onContinue: _continueToReview,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _primaryReturnedSaleLineId(ReturnFlowState flowState) {
    final line = flowState.selectedReturnLines.isNotEmpty
        ? flowState.selectedReturnLines.first
        : null;
    final saleLineId = line?.saleLineId.trim() ?? '';
    return saleLineId.isEmpty ? null : saleLineId;
  }

  Future<void> _handleProductSelected(ReturnExchangeProduct product) async {
    if (product.isOutOfStock || !product.enabled) {
      return;
    }

    final returnedSaleLineId =
        _primaryReturnedSaleLineId(ref.read(returnFlowProvider));
    if (returnedSaleLineId == null) {
      return;
    }

    if (product.hasVariants && product.variantId == null) {
      final catalogProduct = PosCatalogProductSummary(
        productId: product.productId,
        name: product.name,
        categoryName: product.variantDisplayName ?? '',
        basePrice: product.sellingPrice.round(),
        hasVariants: true,
        imageUrl: product.imageStorageKey,
        stockStatus: product.stockStatus,
        availableQty: product.availableQuantity,
      );
      final selection = await showExchangeVariantPicker(
        context: context,
        ref: ref,
        product: catalogProduct,
        currencyCode: product.currencyCode.isNotEmpty
            ? product.currencyCode
            : ref.read(exchangeReplacementSearchProvider).currencyCode,
      );
      if (selection == null || !selection.isSelectable) {
        return;
      }
      await ref.read(returnExchangeFlowProvider.notifier).saveReplacement(
            returnedSaleLineId: returnedSaleLineId,
            replacementProductId: selection.productId,
            replacementVariantId: selection.productVariantId,
            quantity: selection.quantity.toDouble(),
          );
      return;
    }

    final selection = await ref
        .read(exchangeReplacementSearchProvider.notifier)
        .resolveSelection(product: product);
    if (selection == null || !selection.isSelectable) {
      return;
    }

    await ref.read(returnExchangeFlowProvider.notifier).saveReplacement(
          returnedSaleLineId: returnedSaleLineId,
          replacementProductId: selection.productId,
          replacementVariantId: selection.productVariantId,
          quantity: selection.quantity.toDouble(),
        );
  }

  void _goBack() {
    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.chooseOption);
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/pos/returns-refunds/choose-option');
  }

  Future<void> _continueToReview() async {
    final exchangeState = ref.read(returnExchangeFlowProvider);
    if (_isContinuing || !exchangeState.canContinue) {
      return;
    }

    setState(() => _isContinuing = true);

    final previewLoaded =
        await ref.read(returnExchangeFlowProvider.notifier).refreshPreview();
    final refreshed = ref.read(returnExchangeFlowProvider);
    if (!previewLoaded ||
        !refreshed.canContinue ||
        refreshed.preview?.canProceed != true ||
        !mounted) {
      if (mounted) {
        setState(() => _isContinuing = false);
        final error = refreshed.errorMessage;
        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
      return;
    }

    ref.read(returnFlowProvider.notifier).setCreditPreviewConfirmed(true);
    ref.read(returnFlowProvider.notifier).setStep(ReturnFlowSteps.settlement);

    if (!mounted) {
      return;
    }

    await context.push('/pos/returns-refunds/settlement');
    if (mounted) {
      await ref.read(returnExchangeFlowProvider.notifier).hydrate();
      setState(() => _isContinuing = false);
    }
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({
    required this.searchState,
    required this.currencyCode,
    required this.selectedKey,
    required this.onProductSelected,
  });

  final ExchangeReplacementSearchState searchState;
  final String currencyCode;
  final String? selectedKey;
  final Future<void> Function(ReturnExchangeProduct product) onProductSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final notifier = ref.read(exchangeReplacementSearchProvider.notifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReplacementItemsSearchToolbar(
              query: searchState.searchQuery,
              showFilters: searchState.showFilters,
              inStockOnly: searchState.inStockOnly,
              onQueryChanged: notifier.setSearchQuery,
              onToggleFilters: notifier.toggleFilters,
              onInStockOnlyChanged: notifier.setInStockOnly,
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            ReplacementProductsSection(
              products: searchState.products,
              isLoading: searchState.isLoading,
              errorMessage: searchState.errorMessage,
              selectedKey: selectedKey,
              currencyCode: currencyCode,
              onRetry: notifier.loadProducts,
              onProductSelected: onProductSelected,
            ),
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
