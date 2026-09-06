import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_customers_orders_returns_visibility.dart';
import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../discount/presentation/providers/pos_discount_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../sale/presentation/providers/pos_checkout_summary_provider.dart';
import '../../../sale/presentation/widgets/new_sale/pos_new_sale_customer_dialog.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_details_panel.dart';
import '../widgets/customers_page_header.dart';
import '../widgets/customers_search_filter_toolbar.dart';
import '../widgets/customers_table_section.dart';
import '../widgets/pos_customer_purchase_history_dialog.dart';
import '../widgets/pos_edit_customer_dialog.dart';

class PosCustomersScreen extends ConsumerStatefulWidget {
  const PosCustomersScreen({super.key});

  @override
  ConsumerState<PosCustomersScreen> createState() => _PosCustomersScreenState();
}

class _PosCustomersScreenState extends ConsumerState<PosCustomersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final granted =
          ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {};
      if (!PosPermissionAccess.canViewCustomers(granted)) {
        return;
      }
      ref.read(customersProvider.notifier).load(resetPage: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final permissions = ref.watch(effectivePermissionSetProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canViewCustomers(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final customersState = ref.watch(customersProvider);
    if (customersState.isForbidden) {
      return const TenantAdminForbiddenScreen();
    }

    final canEdit = PosPermissionAccess.canEditCustomer(granted);
    final canCreate = PosPermissionAccess.canCreateCustomer(granted);
    final tillOpen = ref.watch(tillProvider).hasOpenSession;
    final canAttachPermission =
        PosPermissionAccess.canAttachCustomerToSale(granted);
    final canDeactivate =
        PosPermissionAccess.canDeactivateCustomer(granted);
    final canViewPurchaseHistory =
        PosCustomersOrdersReturnsVisibility.canShowPurchaseHistory(
      permissions,
    );
    final canShowSearch =
        PosCustomersOrdersReturnsVisibility.canShowCustomerSearch(permissions);
    final canShowFilters =
        PosCustomersOrdersReturnsVisibility.canShowCustomerFilters(permissions);
    final canShowPagination =
        PosCustomersOrdersReturnsVisibility.canShowCustomerPagination(
      permissions,
    );
    final selected = customersState.selectedCustomer;
    final canAttach = selected != null &&
        selected.isActive &&
        tillOpen &&
        canAttachPermission &&
        !customersState.isAttaching;
    final attachDisabledReason = selected == null
        ? 'Select a customer first'
        : !selected.isActive
            ? 'Only active customers can be attached to a sale'
            : !tillOpen
                ? 'Open a till session to attach a customer to a sale'
                : !canAttachPermission
                    ? 'You do not have permission to attach a customer to a sale'
                    : null;

    return ColoredBox(
      color: TenantAdminColors.posHomeDarkBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const padding = EdgeInsets.fromLTRB(14, 10, 14, 10);
          final splitView = width >= 900;
          final showSecondaryColumns = width >= 1150;
          final useCardLayout = width < 750;

          return Padding(
            padding: padding,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E6ED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CustomersPageHeader(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: splitView && selected != null
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 62,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: const Color(0xFFE2E6ED)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      CustomersSearchFilterToolbar(
                                        query: customersState.query,
                                        statusFilter:
                                            customersState.statusFilter,
                                        sourceFilter:
                                            customersState.sourceFilter,
                                        onSearchChanged: (value) => ref
                                            .read(customersProvider.notifier)
                                            .setSearchQuery(value),
                                        onStatusChanged: (value) => ref
                                            .read(customersProvider.notifier)
                                            .setStatusFilter(value),
                                        onSourceChanged: (value) => ref
                                            .read(customersProvider.notifier)
                                            .setSourceFilter(value),
                                        onClear: () => ref
                                            .read(customersProvider.notifier)
                                            .clearFilters(),
                                        canAddCustomer: canCreate,
                                        onAddCustomer: _addCustomer,
                                        canShowSearch: canShowSearch,
                                        canShowFilters: canShowFilters,
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: CustomersTableSection(
                                          customers:
                                              customersState.visibleItems,
                                          selectedCustomerId:
                                              customersState.selectedCustomerId,
                                          isLoading: customersState.isLoading,
                                          errorMessage:
                                              customersState.errorMessage,
                                          query: customersState.query,
                                          page: customersState.page,
                                          totalPages: customersState.totalPages,
                                          rangeStart: customersState.rangeStart,
                                          rangeEnd: customersState.rangeEnd,
                                          totalCount: customersState.totalCount,
                                          useCardLayout: false,
                                          showSecondaryColumns:
                                              showSecondaryColumns,
                                          showPagination: canShowPagination,
                                          onSelect: (id) => ref
                                              .read(customersProvider.notifier)
                                              .toggleCustomerSelection(id),
                                          onRetry: () => ref
                                              .read(customersProvider.notifier)
                                              .load(),
                                          onPageChanged: (page) => ref
                                              .read(customersProvider.notifier)
                                              .goToPage(page),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 38,
                                child: CustomerDetailsPanel(
                                  customer: selected,
                                  recentOrders: customersState.recentOrders,
                                  isLoadingDetail:
                                      customersState.isLoadingDetail,
                                  detailErrorMessage:
                                      customersState.detailErrorMessage,
                                  canAttach: canAttach,
                                  showAttachAction: canAttachPermission,
                                  canViewPurchaseHistory: canViewPurchaseHistory,
                                  canEdit: canEdit,
                                  canDeactivate: canDeactivate,
                                  isAttaching: customersState.isAttaching,
                                  attachDisabledReason: attachDisabledReason,
                                  onAttachToSale: _attachToSale,
                                  onViewPurchaseHistory: _viewPurchaseHistory,
                                  onEditCustomer: _editCustomer,
                                  onDeactivateCustomer: _deactivateCustomer,
                                ),
                              ),
                            ],
                          )
                        : Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFE2E6ED)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CustomersSearchFilterToolbar(
                                  query: customersState.query,
                                  statusFilter: customersState.statusFilter,
                                  sourceFilter: customersState.sourceFilter,
                                  onSearchChanged: (value) => ref
                                      .read(customersProvider.notifier)
                                      .setSearchQuery(value),
                                  onStatusChanged: (value) => ref
                                      .read(customersProvider.notifier)
                                      .setStatusFilter(value),
                                  onSourceChanged: (value) => ref
                                      .read(customersProvider.notifier)
                                      .setSourceFilter(value),
                                  onClear: () => ref
                                      .read(customersProvider.notifier)
                                      .clearFilters(),
                                  canAddCustomer: canCreate,
                                  onAddCustomer: _addCustomer,
                                  canShowSearch: canShowSearch,
                                  canShowFilters: canShowFilters,
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: CustomersTableSection(
                                    customers: customersState.visibleItems,
                                    selectedCustomerId:
                                        customersState.selectedCustomerId,
                                    isLoading: customersState.isLoading,
                                    errorMessage: customersState.errorMessage,
                                    query: customersState.query,
                                    page: customersState.page,
                                    totalPages: customersState.totalPages,
                                    rangeStart: customersState.rangeStart,
                                    rangeEnd: customersState.rangeEnd,
                                    totalCount: customersState.totalCount,
                                    useCardLayout: useCardLayout,
                                    showSecondaryColumns:
                                        splitView && showSecondaryColumns,
                                    showPagination: canShowPagination,
                                    onSelect: (id) => splitView
                                        ? ref
                                            .read(customersProvider.notifier)
                                            .toggleCustomerSelection(id)
                                        : _selectOnNarrow(id),
                                    onRetry: () => ref
                                        .read(customersProvider.notifier)
                                        .load(),
                                    onPageChanged: (page) => ref
                                        .read(customersProvider.notifier)
                                        .goToPage(page),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectOnNarrow(String customerId) async {
    await ref.read(customersProvider.notifier).selectCustomer(customerId);
    final customersState = ref.read(customersProvider);
    final selected = customersState.selectedCustomer;
    if (selected == null || !mounted) {
      return;
    }

    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    final tillOpen = ref.read(tillProvider).hasOpenSession;
    final canAttachPermission =
        PosPermissionAccess.canAttachCustomerToSale(granted);
    final canAttach = tillOpen && canAttachPermission && selected.isActive;

    await showCustomerMobileDetailsSheet(
      context: context,
      customer: selected,
      recentOrders: customersState.recentOrders,
      isLoadingDetail: customersState.isLoadingDetail,
      detailErrorMessage: customersState.detailErrorMessage,
      canAttach: canAttach,
      showAttachAction: canAttachPermission,
      canViewPurchaseHistory:
          PosCustomersOrdersReturnsVisibility.canShowPurchaseHistory(
        ref.read(effectivePermissionSetProvider),
      ),
      canEdit: PosPermissionAccess.canEditCustomer(granted),
      canDeactivate: PosPermissionAccess.canDeactivateCustomer(granted),
      isAttaching: customersState.isAttaching,
      attachDisabledReason: !selected.isActive
          ? 'Only active customers can be attached to a sale'
          : !tillOpen
              ? 'Open a till session to attach a customer to a sale'
              : !canAttachPermission
                  ? 'You do not have permission to attach a customer to a sale'
                  : null,
      onAttachToSale: _attachToSale,
      onViewPurchaseHistory: _viewPurchaseHistory,
      onEditCustomer: _editCustomer,
      onDeactivateCustomer: _deactivateCustomer,
    );
  }

  Future<void> _addCustomer() async {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canCreateCustomer(granted)) {
      _showMessage('You do not have permission to create customers.');
      return;
    }

    final created = await showPosNewSaleCustomerDialog(
      context: context,
      ref: ref,
      canCreateCustomer: true,
    );
    if (created == null || !mounted) {
      return;
    }

    await ref.read(customersProvider.notifier).refreshAfterCreate(created);
    if (!mounted) {
      return;
    }
    _showMessage('${created.displayName} added successfully.');
  }

  Future<void> _attachToSale() async {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canAttachCustomerToSale(granted)) {
      _showMessage('You do not have permission to attach a customer to a sale.');
      return;
    }
    if (!ref.read(tillProvider).hasOpenSession) {
      _showMessage('Open a till session before attaching a customer.');
      return;
    }

    final result =
        await ref.read(customersProvider.notifier).attachSelectedToSale();
    if (!mounted || result == null) {
      final message = ref.read(customersProvider).attachMessage;
      if (message != null) {
        _showMessage(message);
      }
      return;
    }

    final previousCustomerId =
        ref.read(posNewSaleCartProvider).selectedCustomer?.customerId;
    ref.read(posNewSaleCartProvider.notifier).setCustomer(result.customer);
    if (previousCustomerId != result.customer.customerId) {
      final rebindError = await rebindPosDiscountsAfterCustomerChange(
        read: ref.read,
        invalidate: ref.invalidate,
      );
      if (!mounted) {
        return;
      }
      if (rebindError != null) {
        _showMessage(rebindError);
        return;
      }
    } else {
      ref.invalidate(posCheckoutSummaryProvider);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('${result.customer.displayName} attached to the active sale.'),
      ),
    );
    context.go('/pos/new-sale');
  }

  void _viewPurchaseHistory() {
    final permissions = ref.read(effectivePermissionSetProvider);
    if (!PosCustomersOrdersReturnsVisibility.canShowPurchaseHistory(
      permissions,
    )) {
      _showMessage('You do not have permission to view purchase history.');
      return;
    }
    final selected = ref.read(customersProvider).selectedCustomer;
    if (selected == null || !mounted) {
      return;
    }
    showPosCustomerPurchaseHistoryDialog(
      context: context,
      ref: ref,
      customer: selected,
    );
  }

  Future<void> _editCustomer() async {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canEditCustomer(granted)) {
      _showMessage('You do not have permission to edit customers.');
      return;
    }

    final selected = ref.read(customersProvider).selectedCustomer;
    if (selected == null || !mounted) {
      return;
    }

    final updated = await showPosEditCustomerDialog(
      context: context,
      ref: ref,
      customer: selected,
    );

    if (updated == null || !mounted) {
      return;
    }

    await ref.read(customersProvider.notifier).refreshAfterMutation();
    _showMessage('Customer updated successfully.');
  }

  Future<void> _deactivateCustomer() async {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canDeactivateCustomer(granted)) {
      _showMessage('You do not have permission to deactivate customers.');
      return;
    }
    final selected = ref.read(customersProvider).selectedCustomer;
    if (selected == null || !selected.isActive || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate customer?'),
        content: Text(
          '${selected.displayName} will no longer be eligible for new sales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(customersProvider.notifier).updateCustomer(
            customerId: selected.customerId,
            fullName: selected.fullName,
            phone: selected.phone,
            email: selected.email,
            status: 'INACTIVE',
          );
      await ref.read(customersProvider.notifier).refreshAfterMutation();
      _showMessage('Customer deactivated successfully.');
    } on DioException catch (error) {
      _showMessage(error.response?.data is Map
          ? (error.response?.data['message']?.toString() ??
              'Unable to deactivate customer.')
          : 'Unable to deactivate customer.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
