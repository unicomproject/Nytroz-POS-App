import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/pos_online_orders_provider.dart';
import '../widgets/online_order_ui.dart';
import '../widgets/oo01_online_orders_widgets.dart';

class PosOnlineOrdersScreen extends ConsumerStatefulWidget {
  const PosOnlineOrdersScreen({super.key});

  @override
  ConsumerState<PosOnlineOrdersScreen> createState() =>
      _PosOnlineOrdersScreenState();
}

class _PosOnlineOrdersScreenState extends ConsumerState<PosOnlineOrdersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(posOnlineOrdersProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posOnlineOrdersProvider);
    final controller = ref.read(posOnlineOrdersProvider.notifier);
    return ColoredBox(
      color: OnlineOrderUi.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Oo01Header(
                      searchController: _searchController,
                      onSearch: controller.setQuery,
                    ),
                    const SizedBox(height: 12),
                    Oo01SummaryRow(summary: state.summary),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Oo01OrderResults(
                        state: state,
                        onOpen: _select,
                        onRetry: controller.load,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _select(String id) => context.push('/pos/online-orders/$id');
}
