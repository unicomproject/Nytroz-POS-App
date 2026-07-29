import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../sale/presentation/widgets/new_sale/pos_new_sale_customer_dialog.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_details_panel.dart';
import '../widgets/customer_summary_cards.dart';
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
      ref.read(customersSummaryProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canViewCustomers(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    final customersState = ref.watch(customersProvider);
    if (customersState.isForbidden) {
      return const TenantAdminForbiddenScreen();
    }

    final summaryState = ref.watch(customersSummaryProvider);
    final canCreate = PosPermissionAccess.canCreateCustomer(granted);
    final canEdit = PosPermissionAccess.canEditCustomer(granted);
    final tillOpen = ref.watch(tillProvider).hasOpenSession;
    final canAttachPermission =
        PosPermissionAccess.canAttachCustomerToSale(granted);
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
      color: TenantAdminColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final padding = width >= TenantAdminBreakpoints.tablet
              ? const EdgeInsets.fromLTRB(28, 24, 28, 20)
              : TenantAdminInsets.pageForWidth(width);
          final splitView = width >= 1050;
          final showSecondaryColumns = width >= 1180;
          final useCardLayout = width < 800;

          return Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomersPageHeader(
                  canCreateCustomer: canCreate,
                  onNewCustomer: () => _openNewCustomer(canCreate: canCreate),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                CustomerSummaryCards(summary: summaryState),
                const SizedBox(height: TenantAdminSpacing.lg),
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
                  onClear: () =>
                      ref.read(customersProvider.notifier).clearFilters(),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                Expanded(
                  child: splitView
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 72,
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
                                useCardLayout: false,
                                showSecondaryColumns: showSecondaryColumns,
                                onSelect: (id) => ref
                                    .read(customersProvider.notifier)
                                    .selectCustomer(id),
                                onRetry: () =>
                                    ref.read(customersProvider.notifier).load(),
                                onPageChanged: (page) => ref
                                    .read(customersProvider.notifier)
                                    .goToPage(page),
                              ),
                            ),
                            const SizedBox(width: TenantAdminSpacing.lg),
                            Expanded(
                              flex: 28,
                              child: CustomerDetailsPanel(
                                customer: selected,
                                recentOrders: customersState.recentOrders,
                                isLoadingDetail: customersState.isLoadingDetail,
                                detailErrorMessage:
                                    customersState.detailErrorMessage,
                                canAttach: canAttach,
                                canViewPurchaseHistory: true,
                                canEdit: canEdit,
                                isAttaching: customersState.isAttaching,
                                attachDisabledReason: attachDisabledReason,
                                onAttachToSale: _attachToSale,
                                onViewPurchaseHistory: _viewPurchaseHistory,
                                onEditCustomer: _editCustomer,
                              ),
                            ),
                          ],
                        )
                      : CustomersTableSection(
                          customers: customersState.visibleItems,
                          selectedCustomerId: customersState.selectedCustomerId,
                          isLoading: customersState.isLoading,
                          errorMessage: customersState.errorMessage,
                          query: customersState.query,
                          page: customersState.page,
                          totalPages: customersState.totalPages,
                          rangeStart: customersState.rangeStart,
                          rangeEnd: customersState.rangeEnd,
                          totalCount: customersState.totalCount,
                          useCardLayout: useCardLayout,
                          showSecondaryColumns: false,
                          onSelect: (id) => _selectOnNarrow(id),
                          onRetry: () =>
                              ref.read(customersProvider.notifier).load(),
                          onPageChanged: (page) => ref
                              .read(customersProvider.notifier)
                              .goToPage(page),
                        ),
                ),
              ],
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
      canViewPurchaseHistory: true,
      canEdit: PosPermissionAccess.canEditCustomer(granted),
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
    );
  }

  Future<void> _openNewCustomer({required bool canCreate}) async {
    if (!canCreate) {
      _showMessage('You do not have permission to create customers.');
      return;
    }

    final created = await showPosNewSaleCustomerDialog(
      context: context,
      ref: ref,
      canCreateCustomer: canCreate,
    );

    if (created == null || !mounted) {
      return;
    }

    await ref.read(customersProvider.notifier).refreshAfterCreate(created);
  }

  Future<void> _attachToSale() async {
    final session = ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    if (!ref.read(tillProvider).hasOpenSession) {
      _showMessage('Open a till session before attaching a customer.');
      return;
    }
    if (!PosPermissionAccess.canAttachCustomerToSale(granted)) {
      _showMessage(
          'You do not have permission to attach a customer to a sale.');
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

    ref.read(posNewSaleCartProvider.notifier).setCustomer(result.customer);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('${result.customer.displayName} attached to the active sale.'),
      ),
    );
    context.go('/pos/new-sale');
  }

  void _viewPurchaseHistory() {
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

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
