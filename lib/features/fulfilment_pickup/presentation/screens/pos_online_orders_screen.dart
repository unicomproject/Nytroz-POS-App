import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../sale/presentation/widgets/new_sale/pos_barcode_scanner_listener.dart';
import '../providers/pos_online_orders_provider.dart';
import '../widgets/online_order_ui.dart';
import '../widgets/oo01_online_orders_widgets.dart';

class PosOnlineOrdersScreen extends ConsumerStatefulWidget {
  const PosOnlineOrdersScreen({super.key});

  @override
  ConsumerState<PosOnlineOrdersScreen> createState() =>
      _PosOnlineOrdersScreenState();
}

class _PosOnlineOrdersScreenState extends ConsumerState<PosOnlineOrdersScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchFocus.addListener(_focusChanged);
    Future.microtask(() {
      if (!mounted) return;
      _searchController.text = ref.read(posOnlineOrdersProvider).query;
      ref.read(posOnlineOrdersProvider.notifier).load();
    });
  }

  void _focusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) setState(() => _resumed = state == AppLifecycleState.resumed);
  }

  void _scan(String value) {
    final query = value.trim();
    if (!mounted ||
        query.isEmpty ||
        !_resumed ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    _searchController.value = TextEditingValue(
        text: query, selection: TextSelection.collapsed(offset: query.length));
    ref.read(posOnlineOrdersProvider.notifier).setQuery(query);
  }

  void _focusScanner() {
    _searchFocus.requestFocus();
    _searchController.selection = TextSelection(
        baseOffset: 0, extentOffset: _searchController.text.length);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchFocus.removeListener(_focusChanged);
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posOnlineOrdersProvider);
    final controller = ref.read(posOnlineOrdersProvider.notifier);
    final canScanCollection = PosPermissionAccess.canScanCollectionQr(
      ref.watch(authSessionProvider)?.permissionCodes.toSet() ?? const {},
    );
    return PosBarcodeScannerListener(
        // Focused input already receives wedge keys through normal onChanged.
        // Background capture uses the canonical HID service, never both paths.
        enabled: _resumed &&
            !_searchFocus.hasFocus &&
            (ModalRoute.of(context)?.isCurrent ?? true),
        onBarcodeScanned: _scan,
        child: ColoredBox(
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
                          searchFocusNode: _searchFocus,
                          onScan: _focusScanner,
                          onCollectionQr: canScanCollection
                              ? () => context
                                  .go('/pos/online-orders/collection/scan')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Oo01SummaryRow(
                          summary: state.summary,
                          selectedStatus: state.status,
                          onStatusSelected: controller.setStatus,
                        ),
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
        ));
  }

  void _select(String id) => context.push('/pos/online-orders/$id');
}
