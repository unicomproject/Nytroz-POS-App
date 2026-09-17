import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/pos_online_order_collection_provider.dart';
import '../widgets/online_order_ui.dart';

/// Bridges Click & Collect balance settlement into the existing cash payment flow.
class CollectionPaymentBridgeScreen extends ConsumerStatefulWidget {
  const CollectionPaymentBridgeScreen({super.key});

  @override
  ConsumerState<CollectionPaymentBridgeScreen> createState() =>
      _CollectionPaymentBridgeScreenState();
}

class _CollectionPaymentBridgeScreenState
    extends ConsumerState<CollectionPaymentBridgeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = ref.read(collectionPaymentContextProvider);
      if (ctx == null) {
        context.go('/pos/online-orders/collection/verification');
        return;
      }
      context.push('/pos/new-sale/payment');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: OnlineOrderUi.canvas,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
