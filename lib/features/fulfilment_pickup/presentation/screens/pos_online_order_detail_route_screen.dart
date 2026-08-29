import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pos_online_orders_provider.dart';
import 'online_order_detail_screen.dart';

class PosOnlineOrderDetailRouteScreen extends ConsumerStatefulWidget {
  const PosOnlineOrderDetailRouteScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<PosOnlineOrderDetailRouteScreen> createState() =>
      _PosOnlineOrderDetailRouteScreenState();
}

class _PosOnlineOrderDetailRouteScreenState
    extends ConsumerState<PosOnlineOrderDetailRouteScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(posOnlineOrdersProvider.notifier).select(widget.orderId),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: OnlineOrderDetailScreen(
          state: ref.watch(posOnlineOrdersProvider),
          showBackButton: true,
        ),
      );
}
