import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/pos_access_codes.dart';
import '../../../../cart/presentation/providers/pos_parked_sale_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'parked_sales/parked_sale_card.dart';
import 'parked_sales/parked_sale_recall_dialog.dart';
import 'parked_sales/parked_sale_scope_filters.dart';
import 'parked_sales/parked_sales_formatters.dart';
import 'parked_sales/parked_sales_header.dart';
import 'parked_sales/parked_sales_pagination.dart';
import 'parked_sales/parked_sales_states.dart';

export 'parked_sales/parked_sale_recall_dialog.dart'
    show PosParkedSaleRecallHandler;

class PosParkedSalesPanel extends ConsumerWidget {
  const PosParkedSalesPanel({
    super.key,
    required this.onRecallSuccess,
    this.onClose,
  });

  final void Function(BuildContext context)? onClose;
  final PosParkedSaleRecallHandler onRecallSuccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(posParkedSaleProvider);
    final operation = ref.watch(posParkedSaleOperationProvider);
    final access = ref.watch(posParkedSaleAccessContextProvider);
    final count = ref.watch(posParkedSaleCountProvider);
    final notifier = ref.read(posParkedSaleProvider.notifier);
    final refreshing = operation == PosParkedSaleOperation.loadingList;

    Widget listBody() => salesAsync.when(
          loading: () => const ParkedSalesLoadingState(),
          error: (error, _) => ParkedSalesLoadError(
            message: safeError(error),
            onRetry: notifier.refresh,
          ),
          data: (sales) => sales.isEmpty
              ? const ParkedSalesEmptyState()
              : ListView.separated(
                  key: const ValueKey('pos-parked-sales-list'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: TenantAdminSpacing.md,
                    vertical: TenantAdminSpacing.xs,
                  ),
                  itemCount: sales.length,
                  separatorBuilder: (_, __) => const SizedBox(
                    height: TenantAdminSpacing.md,
                  ),
                  // Use the panel build context (not the list-item context).
                  // After a successful recall the card is removed from the
                  // list and the item context unmounts before navigation.
                  itemBuilder: (_, index) => ParkedSaleCard(
                    sale: sales[index],
                    canRecall: access.permissions.contains(
                          PosPermissionCodes.heldSalesRecall,
                        ) ||
                        access.permissions.contains(
                          PosPermissionCodes.recallBackendParkedSale,
                        ),
                    // Chunk 2: cancel is independent — create alone must NOT authorize.
                    canCancel: access.permissions.contains(
                      PosPermissionCodes.heldSalesCancel,
                    ),
                    onRecallSuccess: (__, recallRef, sale) =>
                        onRecallSuccess(context, recallRef, sale),
                  ),
                ),
        );

    return Column(
      key: const ValueKey('pos-parked-sales-panel'),
      children: [
        ParkedSalesListHeader(
          count: count,
          refreshing: refreshing,
          onRefresh: refreshing ? null : notifier.refresh,
          onClose: onClose == null ? null : () => onClose!(context),
        ),
        ParkedSaleScopeFilters(
          selected: notifier.scope,
          loading: refreshing,
          onSelected: notifier.selectScope,
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        if (salesAsync.hasValue && notifier.lastFailure != null)
          ParkedSalesInlineError(message: notifier.lastFailure!.message),
        Expanded(
          child: listBody(),
        ),
        ParkedSalesPaginationBar(
          page: notifier.page,
          pageSize: notifier.pageSize,
          totalCount: notifier.totalCount,
          loading: refreshing,
          onPage: notifier.goToPage,
        ),
      ],
    );
  }
}
