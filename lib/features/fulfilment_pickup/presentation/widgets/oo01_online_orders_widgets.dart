import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_cached_network_image.dart';
import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import 'online_order_ui.dart';

class Oo01Header extends StatelessWidget {
  const Oo01Header({
    required this.searchController,
    required this.onSearch,
    super.key,
  });
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Online Orders', style: OnlineOrderUi.title),
              SizedBox(height: 3),
              Text(
                'Click & Collect orders from your online store',
                style: OnlineOrderUi.subtitle,
              ),
            ],
          );
          final search = Semantics(
            textField: true,
            label: 'Search online orders',
            child: TextField(
              controller: searchController,
              onChanged: onSearch,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText:
                    'Search by order number, customer, phone or collection code',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          );
          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [heading, const SizedBox(height: 12), search],
            );
          }
          return Row(children: [
            const Expanded(child: heading),
            const SizedBox(width: 20),
            SizedBox(width: constraints.maxWidth * .42, child: search),
          ]);
        },
      );
}

class Oo01SummaryRow extends StatelessWidget {
  const Oo01SummaryRow({required this.summary, super.key});
  final PosOnlineOrderSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        'New',
        summary.newOrders,
        Icons.shopping_bag_outlined,
        OnlineOrderSummarySemantic.newOrder
      ),
      (
        'Preparing',
        summary.preparing,
        Icons.inventory_2_outlined,
        OnlineOrderSummarySemantic.preparing
      ),
      (
        'Ready',
        summary.ready,
        Icons.shopping_bag_outlined,
        OnlineOrderSummarySemantic.ready
      ),
      (
        'Delayed',
        summary.overdue,
        Icons.schedule,
        OnlineOrderSummarySemantic.delayed
      ),
      (
        'Collected',
        summary.collected,
        Icons.check_circle_outline,
        OnlineOrderSummarySemantic.collected
      ),
      (
        'Cancelled',
        summary.cancelled,
        Icons.cancel_outlined,
        OnlineOrderSummarySemantic.cancelled
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 6
          : constraints.maxWidth >= 600
              ? 3
              : 2;
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final card in cards)
            SizedBox(
              width: width,
              child: OnlineOrderSummaryCard(
                title: card.$1,
                count: card.$2,
                icon: card.$3,
                semantic: card.$4,
              ),
            ),
        ],
      );
    });
  }
}

class Oo01OrderResults extends StatelessWidget {
  const Oo01OrderResults({
    required this.state,
    required this.onOpen,
    required this.onRetry,
    super.key,
  });
  final PosOnlineOrdersState state;
  final ValueChanged<String> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return OnlineOrderScreenState(
        message: state.errorMessage!,
        icon: Icons.error_outline,
        onRetry: onRetry,
      );
    }
    if (state.items.isEmpty) {
      return OnlineOrderScreenState(
        message: state.query.isEmpty
            ? 'No online orders are available.'
            : 'No orders match your search.',
        icon: state.query.isEmpty ? Icons.inbox_outlined : Icons.search_off,
      );
    }
    return Column(children: [
      if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
      Expanded(
        child: ListView.separated(
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 9),
          itemBuilder: (context, index) => Oo01OrderCard(
            order: state.items[index],
            serverTime: state.serverTime,
            onTap: () => onOpen(state.items[index].id),
          ),
        ),
      ),
    ]);
  }
}

class Oo01OrderCard extends StatelessWidget {
  const Oo01OrderCard({
    required this.order,
    required this.onTap,
    this.serverTime,
    super.key,
  });
  final PosOnlineOrder order;
  final DateTime? serverTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Semantics(
          button: true,
          label: 'Open order details for ${order.orderNumber}',
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFFE1E7F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: constraints.maxWidth < 720 ? _compact() : _wide(),
              ),
            ),
          ),
        ),
      );

  Widget _wide() => Row(children: [
        Expanded(flex: 23, child: _identity()),
        Expanded(flex: 21, child: _customer()),
        Expanded(flex: 18, child: _collection()),
        Expanded(flex: 8, child: _items()),
        Expanded(flex: 16, child: _status()),
        Expanded(flex: 14, child: _previews()),
        const Icon(Icons.chevron_right),
      ]);

  Widget _compact() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: _identity()),
            const Icon(Icons.chevron_right),
          ]),
          const SizedBox(height: 10),
          _customer(),
          const SizedBox(height: 10),
          _collection(),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _items()),
            Flexible(flex: 2, child: _status()),
          ]),
          const SizedBox(height: 10),
          _previews(),
        ],
      );

  Widget _identity() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.orderNumber,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          if (order.externalOrderReference != null)
            Text('Code: ${order.externalOrderReference}',
                style: OnlineOrderUi.subtitle),
        ],
      );

  Widget _customer() => Row(children: [
        const CircleAvatar(radius: 15, child: Icon(Icons.person, size: 17)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.customerName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (order.customerPhone?.isNotEmpty ?? false)
                Text(order.customerPhone!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OnlineOrderUi.subtitle),
            ],
          ),
        ),
      ]);

  Widget _collection() {
    final start = order.collectionAt;
    if (start == null) return const Text('Not scheduled');
    final reference = (serverTime ?? DateTime.now()).toLocal();
    final local = start.toLocal();
    final delta = DateTime(local.year, local.month, local.day)
        .difference(DateTime(reference.year, reference.month, reference.day))
        .inDays;
    final day = switch (delta) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => DateFormat('dd MMM yyyy').format(local),
    };
    final end = order.collectionEndAt;
    final window = end == null
        ? DateFormat('h:mm a').format(local)
        : '${DateFormat('h:mm').format(local)} – ${DateFormat('h:mm a').format(end.toLocal())}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(day, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(window, style: OnlineOrderUi.subtitle),
      ],
    );
  }

  Widget _items() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${order.lineCount}',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(order.lineCount == 1 ? 'item' : 'items',
              style: OnlineOrderUi.subtitle),
        ],
      );

  Widget _status() => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          OnlineOrderStatusChip(label: order.statusLabel, status: order.status),
          PaymentStatusChip(status: order.paymentStatus),
        ],
      );

  Widget _previews() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final preview in order.productPreviews.take(4))
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: AppCachedNetworkImage(
                  imageUrl: preview.imageUrl,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                  memCacheWidth: 80,
                  memCacheHeight: 80,
                  errorWidget: Container(
                    width: 34,
                    height: 34,
                    color: const Color(0xFFF0F3F8),
                    child: const Icon(Icons.inventory_2_outlined, size: 17),
                  ),
                ),
              ),
            ),
          if (order.remainingPreviewCount > 0)
            CircleAvatar(
              radius: 17,
              child: Text('+${order.remainingPreviewCount}',
                  style: const TextStyle(fontSize: 11)),
            ),
        ],
      );
}
