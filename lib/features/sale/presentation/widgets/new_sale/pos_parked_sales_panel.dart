import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/access/pos_access_codes.dart';
import '../../../../../shared/presentation/app_modal.dart';
import '../../../../../shared/widgets/pos_action_buttons.dart';
import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../cart/presentation/providers/pos_parked_sale_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

typedef PosParkedSaleRecallHandler = void Function(
  BuildContext context,
  WidgetRef ref,
  PosParkedSale sale,
);

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
          loading: () => const _LoadingState(),
          error: (error, _) => _LoadError(
            message: _safeError(error),
            onRetry: notifier.refresh,
          ),
          data: (sales) => sales.isEmpty
              ? const _EmptyState()
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
                  itemBuilder: (context, index) => _ParkedSaleCard(
                    sale: sales[index],
                    canRecall: access.permissions.contains(
                      PosPermissionCodes.recallBackendParkedSale,
                    ),
                    canCancel: access.permissions.contains(
                      PosPermissionCodes.createParkedSale,
                    ),
                    onRecallSuccess: (_, ref, sale) =>
                        onRecallSuccess(context, ref, sale),
                  ),
                ),
        );

    return Column(
      key: const ValueKey('pos-parked-sales-panel'),
      children: [
        _ListHeader(
          count: count,
          refreshing: refreshing,
          onRefresh: refreshing ? null : notifier.refresh,
          onClose: onClose == null ? null : () => onClose!(context),
        ),
        _ScopeFilters(
          selected: notifier.scope,
          loading: refreshing,
          onSelected: notifier.selectScope,
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        if (salesAsync.hasValue && notifier.lastFailure != null)
          _InlineError(message: notifier.lastFailure!.message),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final summary = _SummaryPanel(
                totalCount: notifier.totalCount,
                totalValue: notifier.totalValue,
                currency: notifier.currency,
                canStartSale: access.permissions.contains(
                  PosPermissionCodes.createSale,
                ),
                compact: constraints.maxWidth < 900,
              );

              if (constraints.maxWidth < 900) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 480,
                        child: listBody(),
                      ),
                      summary,
                    ],
                  ),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: listBody(),
                  ),
                  const SizedBox(width: TenantAdminSpacing.xs),
                  SizedBox(width: 320, child: summary),
                ],
              );
            },
          ),
        ),
        _PaginationBar(
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

class _ScopeFilters extends StatelessWidget {
  const _ScopeFilters({
    required this.selected,
    required this.loading,
    required this.onSelected,
  });

  final PosParkedSaleScope selected;
  final bool loading;
  final ValueChanged<PosParkedSaleScope> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.lg),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: PosParkedSaleScope.values
                .map((scope) {
                  final isSelected = selected == scope;
                  return InkWell(
                    key: ValueKey('parked-sales-scope-${scope.apiValue}'),
                    onTap: loading ? null : () => onSelected(scope),
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? TenantAdminColors.posNewSaleAccent
                            : const Color(0xFFF8FAFC),
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                        border: Border.all(
                          color: isSelected
                              ? TenantAdminColors.posNewSaleAccent
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            scope == PosParkedSaleScope.today
                                ? Icons.calendar_today_outlined
                                : scope == PosParkedSaleScope.currentShift
                                    ? Icons.schedule_outlined
                                    : Icons.layers_outlined,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            scope.label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF334155),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
      );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        backgroundColor: TenantAdminColors.posHomeReturnsCard,
        side: const BorderSide(color: TenantAdminColors.posNewSaleAccent),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        avatar: Icon(
          icon,
          size: 14,
          color: TenantAdminColors.posNewSaleAccent,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.bodyText,
          ),
        ),
      );
}

class _ParkedSaleCard extends ConsumerWidget {
  const _ParkedSaleCard({
    required this.sale,
    required this.canRecall,
    required this.canCancel,
    required this.onRecallSuccess,
  });

  final PosParkedSale sale;
  final bool canRecall, canCancel;
  final PosParkedSaleRecallHandler onRecallSuccess;

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'WC';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, min(2, trimmed.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerName = sale.primaryDisplayName;
    final initials = _getInitials(customerName);

    return Semantics(
      container: true,
      label: 'Parked sale ${sale.reference}. Items: ${sale.itemPreview}',
      child: Container(
        key: ValueKey('parked-sale-card-${sale.id}'),
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Document icon + Reference ... Amount
            Row(
              children: [
                const Icon(
                  Icons.article_outlined,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                const SizedBox(width: 8),
                SelectableText(
                  sale.reference,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatMoney(sale.currency, sale.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Customer Circle + Name + Subtitle
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      customerName == 'Walk-in customer'
                          ? 'Walk-in Customer'
                          : 'Customer',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 3: Metadata Badges (Items, Parked Time, Expires Time)
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MetaChip(
                  icon: Icons.shopping_bag_outlined,
                  label: '${sale.itemCount} ${sale.itemCount == 1 ? 'item' : 'items'}',
                ),
                _Badge(
                  icon: Icons.access_time_rounded,
                  title: 'Parked ${_formatTimeOnly(sale.createdAt)}',
                  subtitle: _formatDateOnly(sale.createdAt),
                ),
                if (sale.expiresAt != null)
                  _Badge(
                    icon: Icons.timer_outlined,
                    title: 'Expires ${_formatTimeOnly(sale.expiresAt!)} Tomorrow',
                    subtitle: _formatDateOnly(sale.expiresAt!),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 4: Item Preview Text (Left) & Action Buttons (Right)
            Row(
              children: [
                Expanded(
                  child: Text(
                    sale.itemPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _SaleRowActions(
                      sale: sale,
                      canRecall: canRecall,
                      canCancel: canCancel,
                      onRecallSuccess: onRecallSuccess,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5EE),
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          border: Border.all(color: const Color(0xFFFFEDD5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFEF4444)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}

class _SaleRowActions extends ConsumerStatefulWidget {
  const _SaleRowActions({
    required this.sale,
    required this.canRecall,
    required this.canCancel,
    required this.onRecallSuccess,
  });

  final PosParkedSale sale;
  final bool canRecall, canCancel;
  final PosParkedSaleRecallHandler onRecallSuccess;

  @override
  ConsumerState<_SaleRowActions> createState() => _SaleRowActionsState();
}

class _SaleRowActionsState extends ConsumerState<_SaleRowActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              key: ValueKey('view-${widget.sale.id}'),
              onPressed: _busy ? null : _handleView,
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text(
                'View Details',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: TenantAdminColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                ),
              ),
            ),
            if (widget.canCancel) ...[
              const SizedBox(width: 6),
              OutlinedButton.icon(
                key: ValueKey('cancel-${widget.sale.id}'),
                onPressed: _busy ? null : _handleCancel,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
                label: const Text(
                  'Cancel Parked Sale',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  foregroundColor: const Color(0xFFEF4444),
                  side: BorderSide(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  ),
                ),
              ),
            ],
            if (widget.canRecall) ...[
              const SizedBox(width: 6),
              FilledButton.icon(
                key: ValueKey('recall-${widget.sale.id}'),
                onPressed: _busy ? null : _handleRecall,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  backgroundColor: TenantAdminColors.posNewSaleAccent,
                  foregroundColor: TenantAdminColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  ),
                ),
                icon: const Icon(Icons.history_rounded, size: 16),
                label: const Text(
                  'Recall Sale',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      );

  Future<void> _handleRecall() => _guard(
      () => _beginRecall(context, ref, widget.sale, widget.onRecallSuccess));

  Future<void> _handleView() => _guard(() => _showView(context, widget.sale));

  Future<void> _handleCancel() =>
      _guard(() => _showCancel(context, ref, widget.sale));

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.totalCount,
    required this.totalValue,
    required this.currency,
    required this.canStartSale,
    this.compact = false,
  });

  final int totalCount, totalValue;
  final String currency;
  final bool canStartSale;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(
          0,
          TenantAdminSpacing.xs,
          TenantAdminSpacing.md,
          TenantAdminSpacing.md,
        ),
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header title area
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1EBFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 20,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Parked Sales Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.sm),

              // Card 1: Total Parked Sales
              Container(
                padding: const EdgeInsets.all(TenantAdminSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  border: Border.all(color: const Color(0xFFE0F2FE)),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFBAE6FD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 16,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Total Parked Sales',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCount',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      'Sales',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),

              // Card 2: Total Parked Value
              Container(
                padding: const EdgeInsets.all(TenantAdminSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFBBF7D0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            size: 16,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Total Parked Value',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMoney(currency, totalValue),
                      key: const ValueKey('parked-sales-total-value'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const Text(
                      'Value',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),

              // Card 3: Start New Sale section
              Container(
                padding: const EdgeInsets.all(TenantAdminSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5EE),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6A00),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start a New Sale',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Create a new sale and start adding items.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TenantAdminSpacing.xs),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TenantAdminColors.posHomeAccentOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(TenantAdminRadius.sm),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Start New Sale',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: canStartSale
                            ? () => context.go('/pos/new-sale')
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.loading,
    required this.onPage,
  });

  final int page, pageSize, totalCount;
  final bool loading;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final pages = totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TenantAdminSpacing.lg,
        TenantAdminSpacing.xs,
        TenantAdminSpacing.lg,
        TenantAdminSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Page $page of $pages',
            style: TenantAdminTextStyles.muted(context),
          ),
          IconButton(
            tooltip: 'Previous page',
            onPressed: loading || page <= 1 ? null : () => onPage(page - 1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: loading || page >= pages ? null : () => onPage(page + 1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.count,
    required this.refreshing,
    required this.onRefresh,
    required this.onClose,
  });

  final int count;
  final bool refreshing;
  final VoidCallback? onRefresh;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          TenantAdminSpacing.lg,
          TenantAdminSpacing.lg,
          TenantAdminSpacing.sm,
          TenantAdminSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parked Sales',
                    style: TenantAdminTextStyles.pageTitle(context),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      '$count active',
                      style: TenantAdminTextStyles.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: refreshing
                  ? 'Refreshing parked sales'
                  : 'Refresh parked sales',
              onPressed: onRefresh,
              icon: refreshing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
            if (onClose != null)
              IconButton(
                tooltip: 'Close Parked Sales',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
      );
}

Future<void> _showView(BuildContext context, PosParkedSale sale) =>
    showAppDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('parked-sale-view-dialog'),
        title: Text('Parked Sale ${sale.reference}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Customer: ${sale.primaryDisplayName}'),
                Text('Parked: ${_formatDateTime(sale.createdAt)}'),
                if (sale.expiresAt != null)
                  Text('Expires: ${_formatDateTime(sale.expiresAt!)}'),
                if (sale.note?.trim().isNotEmpty == true)
                  Text('Note: ${sale.note!.trim()}'),
                const Divider(height: TenantAdminSpacing.xxl),
                ...sale.items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.product.name),
                    subtitle: Text(
                      [
                        ...item.product.selectedAttributes.values,
                        if (item.product.sku?.isNotEmpty == true)
                          'SKU: ${item.product.sku}',
                      ].join(' • '),
                    ),
                    trailing: Text(
                      '${item.quantity} × ${_formatMoney(sale.currency, item.product.price)}\n${_formatMoney(sale.currency, item.product.price * item.quantity)}',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total ${_formatMoney(sale.currency, sale.total)}',
                    style: TenantAdminTextStyles.sectionTitle(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );

Future<void> _beginRecall(
  BuildContext context,
  WidgetRef ref,
  PosParkedSale sale,
  PosParkedSaleRecallHandler onRecallSuccess,
) async {
  if (ref.read(posNewSaleCartProvider).hasItems) {
    await showAppDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Cannot Recall Sale'),
        content: Text(
          'Complete, clear or park the current cart before recalling another sale.',
        ),
      ),
    );
    return;
  }
  final providerContainer = ProviderScope.containerOf(context);
  final recalled = await showAppDialog<PosParkedSale>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UncontrolledProviderScope(
      container: providerContainer,
      child: _RecallDialog(sale: sale),
    ),
  );
  if (recalled == null) {
    return;
  }
  if (!context.mounted) {
    return;
  }
  _surfaceRecallValidationMessages(context, ref);
  onRecallSuccess(context, ref, recalled);
}

void _surfaceRecallValidationMessages(BuildContext context, WidgetRef ref) {
  final messages = ref
          .read(posParkedSaleProvider.notifier)
          .lastRecall
          ?.checkoutSummary
          .validationMessages ??
      const <String>[];
  if (messages.isEmpty) {
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(messages.join('\n'))));
}

class _RecallDialog extends ConsumerStatefulWidget {
  const _RecallDialog({required this.sale});

  final PosParkedSale sale;

  @override
  ConsumerState<_RecallDialog> createState() => _RecallDialogState();
}

class _RecallDialogState extends ConsumerState<_RecallDialog> {
  String? error;

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(posParkedSaleOperationProvider) ==
        PosParkedSaleOperation.recalling;

    return PopScope(
      canPop: !loading,
      child: AlertDialog(
        key: const ValueKey('recall-sale-dialog'),
        backgroundColor: TenantAdminColors.surface,
        surfaceTintColor: TenantAdminColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        ),
        title: Text(
          'Recall Sale',
          style: TenantAdminTextStyles.sectionTitle(context),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Return this parked sale to the active cart?'),
            const SizedBox(height: TenantAdminSpacing.md),
            _ConfirmationSummary(sale: widget.sale),
            if (error != null) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              _InlineError(message: error!),
            ],
          ],
        ),
        actions: [
          OutlinedButton(
            key: const ValueKey('recall-sale-cancel'),
            onPressed: loading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize:
                  const Size(104, PosPrimaryActionTokens.compactHeight),
              foregroundColor: TenantAdminColors.bodyText,
              side: const BorderSide(color: TenantAdminColors.bodyText),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton.icon(
            key: const ValueKey('recall-sale-confirm'),
            onPressed: loading ? null : _recall,
            style: FilledButton.styleFrom(
              minimumSize:
                  const Size(136, PosPrimaryActionTokens.compactHeight),
              backgroundColor: TenantAdminColors.posNewSaleAccent,
              foregroundColor: TenantAdminColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
            ),
            icon: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TenantAdminColors.surface,
                    ),
                  )
                : const Icon(Icons.restore_rounded),
            label: Text(
              loading ? 'Recalling sale' : 'Recall Sale',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recall() async {
    setState(() => error = null);
    try {
      final sale =
          await ref.read(posParkedSaleProvider.notifier).recall(widget.sale.id);
      if (mounted && sale != null) Navigator.of(context).pop(sale);
    } catch (e) {
      if (mounted) setState(() => error = _safeError(e));
    }
  }
}

Future<void> _showCancel(
  BuildContext context,
  WidgetRef ref,
  PosParkedSale sale,
) async {
  final providerContainer = ProviderScope.containerOf(context);
  await showAppDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UncontrolledProviderScope(
      container: providerContainer,
      child: _CancelDialog(sale: sale),
    ),
  );
}

class _CancelDialog extends ConsumerStatefulWidget {
  const _CancelDialog({required this.sale});

  final PosParkedSale sale;

  @override
  ConsumerState<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends ConsumerState<_CancelDialog> {
  final formKey = GlobalKey<FormState>();
  final reason = TextEditingController();
  String? error;

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(posParkedSaleOperationProvider) ==
        PosParkedSaleOperation.cancelling;

    return PopScope(
      canPop: !loading,
      child: AlertDialog(
        title: const Text('Cancel Parked Sale'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cancel this parked sale? This action cannot be undone.',
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                _ConfirmationSummary(sale: widget.sale),
                const SizedBox(height: TenantAdminSpacing.md),
                TextFormField(
                  key: const Key('cancel-parked-sale-reason'),
                  controller: reason,
                  enabled: !loading,
                  maxLength: 250,
                  maxLengthEnforcement: MaxLengthEnforcement.none,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'A cancellation reason is required.';
                    }
                    if (trimmed.length > 250) {
                      return 'Reason must be 250 characters or fewer.';
                    }
                    return null;
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: TenantAdminSpacing.sm),
                  _InlineError(message: error!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.of(context).pop(),
            child: const Text('Keep Sale'),
          ),
          PosPrimaryActionButton(
            label: 'Cancel Parked Sale',
            semanticLabel:
                loading ? 'Cancelling parked sale' : 'Cancel Parked Sale',
            compact: true,
            backgroundColor: Theme.of(context).colorScheme.error,
            isLoading: loading,
            onPressed: loading ? null : _cancel,
          ),
        ],
      ),
    );
  }

  Future<void> _cancel() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => error = null);
    try {
      await ref
          .read(posParkedSaleProvider.notifier)
          .delete(widget.sale.id, reason: reason.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => error = _safeError(e));
    }
  }
}

class _ConfirmationSummary extends StatelessWidget {
  const _ConfirmationSummary({required this.sale});

  final PosParkedSale sale;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('recall-sale-summary'),
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: TenantAdminColors.posHomeReturnsCard,
          border: Border.all(color: TenantAdminColors.posNewSaleAccent),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              sale.reference,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(sale.primaryDisplayName),
            Text(
              '${sale.itemCount} items • ${_formatMoney(sale.currency, sale.total)}',
            ),
            if (sale.expiresAt != null)
              Text('Expires ${_formatDateTime(sale.expiresAt!)}'),
          ],
        ),
      );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => Center(
        child: Semantics(
          label: 'Loading parked sales',
          child: const CircularProgressIndicator(),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_circle_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              'No parked sales available',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              'Parked sales will appear here.',
              style: TenantAdminTextStyles.muted(context),
            ),
          ],
        ),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InlineError(message: message),
              const SizedBox(height: TenantAdminSpacing.md),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.lg),
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: TenantAdminSpacing.sm),
            Flexible(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _safeError(Object error) {
  final value = error.toString().trim();
  return value.isEmpty
      ? 'Parked Sale operation failed. Please try again.'
      : value;
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${_two(local.month)}-${_two(local.day)} ${_two(local.hour)}:${_two(local.minute)}';
}

String _formatDateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${_two(local.month)}-${_two(local.day)}';
}

String _formatTimeOnly(DateTime value) {
  final local = value.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

String _formatMoney(String currency, int value) =>
    '$currency ${_number(value)}.00';

String _number(int value) {
  final raw = value.toString();
  final b = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    b.write(raw[i]);
    final remaining = raw.length - i;
    if (remaining > 1 && remaining % 3 == 1) b.write(',');
  }
  return b.toString();
}

String _two(int value) => value.toString().padLeft(2, '0');
