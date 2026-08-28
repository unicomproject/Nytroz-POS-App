import 'package:flutter/material.dart';

import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import 'online_order_ui.dart';

class OnlineOrdersHeader extends StatelessWidget {
  const OnlineOrdersHeader({
    required this.controller,
    required this.onSearch,
    required this.onRefresh,
    required this.onOpenFilters,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < OnlineOrderUi.tabletLandscapeBreakpoint;
          const heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Online Orders', style: OnlineOrderUi.title),
              Text(
                'Manage click & collect orders from confirmation to collection.',
                style: OnlineOrderUi.subtitle,
              ),
            ],
          );
          final search = TextField(
            controller: controller,
            onSubmitted: onSearch,
            decoration: InputDecoration(
              hintText: 'Search by order number or customer...',
              prefixIcon: const Icon(Icons.search, size: 22),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDCE3EE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDCE3EE)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: heading),
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, searchConstraints) {
                    final button = OutlinedButton.icon(
                      onPressed: onOpenFilters,
                      icon: const Icon(Icons.tune),
                      label: const Text('Filters'),
                      style: _filterButtonStyle(),
                    );
                    if (searchConstraints.maxWidth < 520) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          search,
                          const SizedBox(height: 8),
                          button,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: search),
                        const SizedBox(width: 8),
                        button,
                      ],
                    );
                  },
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: heading),
              SizedBox(width: 420, child: search),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onOpenFilters,
                icon: const Icon(Icons.tune),
                label: const Text('Filters'),
                style: _filterButtonStyle(),
              ),
            ],
          );
        },
      );

  static ButtonStyle _filterButtonStyle() => OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF3156D8),
        backgroundColor: const Color(0xFFF3F6FF),
        side: const BorderSide(color: Color(0xFFD7E0FA)),
        minimumSize: const Size(112, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
}

class OnlineOrderStatusSummary extends StatelessWidget {
  const OnlineOrderStatusSummary({required this.summary, super.key});

  final PosOnlineOrderSummary summary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final tiles = [
            _SummaryTile('New', summary.newOrders, Icons.shopping_bag_outlined,
                Colors.blue),
            _SummaryTile('Preparing', summary.preparing,
                Icons.inventory_2_outlined, Colors.deepOrange),
            _SummaryTile('Ready', summary.ready, Icons.shopping_bag_outlined,
                Colors.green),
            _SummaryTile(
                'Delayed', summary.overdue, Icons.schedule, Colors.red),
            _SummaryTile('Collected', summary.collected,
                Icons.check_circle_outline, Colors.deepPurple),
            _SummaryTile('Cancelled', summary.cancelled, Icons.cancel_outlined,
                Colors.blueGrey),
          ];
          if (constraints.maxWidth >= OnlineOrderUi.tabletLandscapeBreakpoint) {
            return Row(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  Expanded(child: tiles[i]),
                  if (i != tiles.length - 1) const SizedBox(width: 8),
                ],
              ],
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tiles
                  .map((tile) => SizedBox(width: 180, child: tile))
                  .toList(growable: false),
            ),
          );
        },
      );
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDCE3EE)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: OnlineOrderUi.subtitle),
                    const SizedBox(height: 3),
                    Text(
                      '$value',
                      style: const TextStyle(
                        color: OnlineOrderUi.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
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

class OnlineOrderStatusTabs extends StatelessWidget {
  const OnlineOrderStatusTabs({
    required this.summary,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PosOnlineOrderSummary summary;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <(String?, String)>[
      (null, 'All Orders (${summary.total})'),
      ('PENDING_CONFIRMATION', 'New (${summary.newOrders})'),
      ('PREPARING', 'Preparing (${summary.preparing})'),
      ('READY_FOR_COLLECTION', 'Ready (${summary.ready})'),
      ('DELAYED', 'Delayed (${summary.overdue})'),
      ('COMPLETED', 'Collected (${summary.collected})'),
      ('CANCELLED', 'Cancelled (${summary.cancelled})'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items
            .map(
              (item) => _StatusTab(
                label: item.$2,
                selected: value == item.$1,
                onTap: () => onChanged(item.$1),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? const Color(0xFFFFF7F2) : Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      selected ? OnlineOrderUi.accent : const Color(0xFFDCE3EE),
                  width: selected ? 2 : 1,
                ),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? OnlineOrderUi.accent : OnlineOrderUi.ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      );
}

class OnlineOrderFilterBar extends StatelessWidget {
  const OnlineOrderFilterBar({
    required this.summary,
    required this.status,
    required this.onStatus,
    super.key,
  });

  final PosOnlineOrderSummary summary;
  final String? status;
  final ValueChanged<String?> onStatus;

  @override
  Widget build(BuildContext context) => OnlineOrderStatusTabs(
        summary: summary,
        value: status,
        onChanged: onStatus,
      );
}

class OnlineOrderSortControl extends StatelessWidget {
  const OnlineOrderSortControl({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PosOnlineOrderSort value;
  final ValueChanged<PosOnlineOrderSort> onChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<PosOnlineOrderSort>(
        initialValue: value,
        onSelected: onChanged,
        position: PopupMenuPosition.under,
        constraints: const BoxConstraints(minWidth: 250),
        itemBuilder: (_) => PosOnlineOrderSort.values
            .map(
              (sort) => PopupMenuItem(
                value: sort,
                child: Row(
                  children: [
                    Expanded(child: Text(sort.label)),
                    if (sort == value)
                      const Icon(Icons.check, color: Color(0xFF3156D8)),
                  ],
                ),
              ),
            )
            .toList(growable: false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDCE3EE)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OnlineOrderUi.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ],
          ),
        ),
      );
}

class OnlineOrderQueueToolbar extends StatelessWidget {
  const OnlineOrderQueueToolbar({
    required this.compact,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool compact;
  final PosOnlineOrderSort value;
  final ValueChanged<PosOnlineOrderSort> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(
            child: Text(
              'Orders queue',
              style: TextStyle(
                color: OnlineOrderUi.ink,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          if (!compact) const Text('Sort by: ', style: OnlineOrderUi.subtitle),
          Flexible(
            child: OnlineOrderSortControl(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      );
}

class OnlineOrderFilterSheet extends StatelessWidget {
  const OnlineOrderFilterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const OnlineOrderFilterSheet(),
      );

  @override
  Widget build(BuildContext context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('More filters', style: OnlineOrderUi.title),
              SizedBox(height: 12),
              Text(
                'Payment and urgency filters are unavailable because the canonical list API does not expose those query contracts.',
              ),
            ],
          ),
        ),
      );
}

class ResponsiveOnlineOrderList extends StatelessWidget {
  const ResponsiveOnlineOrderList({
    required this.state,
    required this.onSelect,
    required this.onPage,
    required this.onRetry,
    super.key,
  });

  final PosOnlineOrdersState state;
  final ValueChanged<String> onSelect;
  final ValueChanged<int> onPage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (state.isLoading) const LinearProgressIndicator(),
            if (state.errorMessage != null)
              Expanded(
                child: OnlineOrderScreenState(
                  message: state.errorMessage!,
                  icon: Icons.error_outline,
                  onRetry: onRetry,
                ),
              )
            else if (!state.isLoading && state.items.isEmpty)
              const Expanded(
                child: OnlineOrderScreenState(
                  message: 'No online orders found.',
                ),
              )
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) =>
                      constraints.maxWidth >= OnlineOrderUi.desktopBreakpoint
                          ? OnlineOrdersTable(
                              orders: state.items,
                              onSelect: onSelect,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: state.items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) => OnlineOrderCard(
                                order: state.items[index],
                                onTap: () => onSelect(state.items[index].id),
                              ),
                            ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final pageCount =
                      state.totalPages == 0 ? 1 : state.totalPages;
                  final firstItem = state.totalCount == 0
                      ? 0
                      : ((state.page - 1) * state.pageSize) + 1;
                  final lastItem =
                      (state.page * state.pageSize).clamp(0, state.totalCount);
                  final useNumberedPages = constraints.maxWidth >= 1200;
                  final visiblePages = List<int>.generate(
                    useNumberedPages ? (pageCount > 5 ? 5 : pageCount) : 0,
                    (index) => index + 1,
                  );
                  final pagination = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: state.page > 1
                            ? () => onPage(state.page - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      for (final page in visiblePages)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: page == state.page
                              ? FilledButton(
                                  onPressed: () => onPage(page),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(38, 38),
                                    padding: EdgeInsets.zero,
                                    backgroundColor: OnlineOrderUi.accent,
                                  ),
                                  child: Text('$page'),
                                )
                              : OutlinedButton(
                                  onPressed: () => onPage(page),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(38, 38),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text('$page'),
                                ),
                        ),
                      if (pageCount > 5)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('…'),
                        ),
                      if (!useNumberedPages)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text('Page ${state.page} of $pageCount'),
                        ),
                      IconButton(
                        onPressed: state.page < state.totalPages
                            ? () => onPage(state.page + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  );
                  if (constraints.maxWidth < OnlineOrderUi.desktopBreakpoint) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Showing $firstItem to $lastItem of ${state.totalCount} orders',
                        ),
                        const SizedBox(height: 4),
                        if (constraints.maxWidth < 600)
                          Row(
                            children: [
                              IconButton(
                                onPressed: state.page > 1
                                    ? () => onPage(state.page - 1)
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Expanded(
                                child: Text(
                                  'Page ${state.page} of $pageCount',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: state.page < state.totalPages
                                    ? () => onPage(state.page + 1)
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          )
                        else
                          Align(
                            alignment: Alignment.centerRight,
                            child: pagination,
                          ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Text(
                        'Showing $firstItem to $lastItem of ${state.totalCount} orders',
                      ),
                      const Spacer(),
                      Flexible(child: pagination),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class OnlineOrdersTable extends StatelessWidget {
  const OnlineOrdersTable({
    required this.orders,
    required this.onSelect,
    super.key,
  });

  final List<PosOnlineOrder> orders;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          const _TableRow(
            order: 'Order',
            customer: 'Customer',
            items: 'Items',
            collection: 'Collection time',
            payment: 'Payment',
            status: 'Status',
            header: true,
          ),
          for (final order in orders)
            InkWell(
              onTap: () => onSelect(order.id),
              child: _TableRow(
                order: order.orderNumber,
                orderMeta: order.placedAt == null
                    ? null
                    : 'Placed ${OnlineOrderUi.collection(order.placedAt)}',
                customer: order.customerName,
                customerMeta: order.customerPhone,
                items:
                    '${order.lineCount} ${order.lineCount == 1 ? 'line' : 'lines'}',
                itemsMeta: 'View items',
                collection: OnlineOrderUi.collection(order.collectionAt),
                payment: order.paymentStatus,
                status: order.statusLabel,
                statusCode: order.status,
                onOpen: () => onSelect(order.id),
              ),
            ),
        ],
      );
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.order,
    required this.customer,
    required this.items,
    required this.collection,
    required this.payment,
    required this.status,
    this.header = false,
    this.orderMeta,
    this.customerMeta,
    this.itemsMeta,
    this.statusCode,
    this.onOpen,
  });

  final String order;
  final String customer;
  final String items;
  final String collection;
  final String payment;
  final String status;
  final bool header;
  final String? orderMeta;
  final String? customerMeta;
  final String? itemsMeta;
  final String? statusCode;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: header ? FontWeight.w800 : FontWeight.w500,
      color: header ? OnlineOrderUi.ink : null,
      fontSize: header ? 12 : 13,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9EDF5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child:
                _TableCell(primary: order, secondary: orderMeta, style: style),
          ),
          Expanded(
            flex: 3,
            child: _TableCell(
              primary: customer,
              secondary: customerMeta,
              style: style,
            ),
          ),
          Expanded(
            flex: 2,
            child: _TableCell(
              primary: items,
              secondary: itemsMeta,
              secondaryColor: const Color(0xFF3156D8),
              style: style,
            ),
          ),
          Expanded(flex: 3, child: Text(collection, style: style)),
          Expanded(
            flex: 2,
            child: header
                ? Text(status, style: style)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: OnlineOrderStatusChip(
                      label: status,
                      status: statusCode ?? status,
                    ),
                  ),
          ),
          Expanded(
            flex: 2,
            child: header
                ? Text(payment, style: style)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: PaymentStatusChip(status: payment),
                  ),
          ),
          SizedBox(
            width: 70,
            child: header
                ? Text('Actions', textAlign: TextAlign.end, style: style)
                : Align(
                    alignment: Alignment.centerRight,
                    child: OnlineOrderActionButton(onPressed: onOpen),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.primary,
    required this.secondary,
    required this.style,
    this.secondaryColor,
  });

  final String primary;
  final String? secondary;
  final TextStyle style;
  final Color? secondaryColor;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            primary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
          if (secondary?.isNotEmpty ?? false)
            Text(
              secondary!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OnlineOrderUi.subtitle.copyWith(color: secondaryColor),
            ),
        ],
      );
}

class OnlineOrderActionButton extends StatelessWidget {
  const OnlineOrderActionButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 38,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: OnlineOrderUi.ink,
            side: const BorderSide(color: Color(0xFFDCE3EE)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Icon(Icons.chevron_right, size: 20),
        ),
      );
}

class OnlineOrderCard extends StatelessWidget {
  const OnlineOrderCard({required this.order, required this.onTap, super.key});

  final PosOnlineOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth >= OnlineOrderUi.phoneBreakpoint
                ? _TabletOrderCard(order: order, onTap: onTap)
                : _PhoneOrderCard(order: order, onTap: onTap),
      );
}

class _TabletOrderCard extends StatelessWidget {
  const _TabletOrderCard({required this.order, required this.onTap});

  final PosOnlineOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: _OrderIdentity(order: order)),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _LabeledValue(
                  label: 'Collection',
                  child: CollectionUrgencyIndicator(
                    collectionAt: order.collectionAt,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _LabeledValue(
                  label: 'Items / Payment / Amount',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text('${order.lineCount} lines'),
                      PaymentStatusChip(status: order.paymentStatus),
                      Text(
                        OnlineOrderUi.money(
                          order.currencyCode,
                          order.totalAmount,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 136,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OnlineOrderStatusChip(
                      label: order.statusLabel,
                      status: order.status,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: onTap, child: const Text('Open')),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _PhoneOrderCard extends StatelessWidget {
  const _PhoneOrderCard({required this.order, required this.onTap});

  final PosOnlineOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _OrderIdentity(order: order)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: OnlineOrderStatusChip(
                      label: order.statusLabel,
                      status: order.status,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 18,
                runSpacing: 12,
                children: [
                  _PhoneField(
                      label: 'Items', value: '${order.lineCount} lines'),
                  _LabeledValue(
                    label: 'Payment',
                    child: PaymentStatusChip(status: order.paymentStatus),
                  ),
                  _LabeledValue(
                    label: 'Collection',
                    child: CollectionUrgencyIndicator(
                      collectionAt: order.collectionAt,
                    ),
                  ),
                  _PhoneField(
                    label: 'Amount',
                    value: OnlineOrderUi.money(
                      order.currencyCode,
                      order.totalAmount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: OnlineOrderUi.accent,
                ),
                child: const Text('Open Order'),
              ),
            ],
          ),
        ),
      );
}

class _OrderIdentity extends StatelessWidget {
  const _OrderIdentity({required this.order});

  final PosOnlineOrder order;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.orderNumber,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(order.customerName,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (order.customerPhone?.isNotEmpty ?? false)
            Text(
              order.customerPhone!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OnlineOrderUi.subtitle,
            ),
        ],
      );
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: OnlineOrderUi.subtitle),
          const SizedBox(height: 5),
          child,
        ],
      );
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => _LabeledValue(
        label: label,
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
}
