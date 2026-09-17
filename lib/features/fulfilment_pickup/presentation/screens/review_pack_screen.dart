import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import '../utils/review_pack_error_mapper.dart';
import '../widgets/online_order_ui.dart';
import '../widgets/review_pack/picked_items_list.dart';
import '../widgets/review_pack/review_pack_header.dart';
import '../widgets/review_pack/review_pack_sidebar.dart';

class ReviewPackScreen extends ConsumerStatefulWidget {
  const ReviewPackScreen({
    required this.order,
    this.onBackToPickItems,
    super.key,
  });

  final PosPickingOrder order;
  final VoidCallback? onBackToPickItems;

  @override
  ConsumerState<ReviewPackScreen> createState() => _ReviewPackScreenState();
}

class _ReviewPackScreenState extends ConsumerState<ReviewPackScreen> {
  static const packingNoteMaxLength = 200;

  late final TextEditingController _notes;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController();
    _notes.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order =
        ref.watch(posPickingOrderProvider(widget.order.orderId)).maybeWhen(
              data: (value) => value,
              orElse: () => widget.order,
            );
    final granted =
        ref.watch(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    final canViewPacking =
        PosPermissionAccess.canViewOnlineOrderPacking(granted);
    final canPack = PosPermissionAccess.canPackOnlineOrder(granted);
    final canMarkReady = PosPermissionAccess.canMarkOnlineOrderReady(granted);

    if (!canViewPacking) {
      return const OnlineOrderScreenState(
        message: 'Packing workspace permission is required.',
        icon: Icons.lock_outline,
      );
    }

    if (order.isTerminal) {
      return Column(
        children: [
          if (widget.onBackToPickItems != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onBackToPickItems,
                icon: const Icon(Icons.arrow_back, size: 17),
                label: const Text('Back'),
              ),
            ),
          const Expanded(
            child: OnlineOrderScreenState(
              message: 'This order is no longer available for packing.',
              icon: Icons.block_outlined,
            ),
          ),
        ],
      );
    }

    final primaryEnabled = !_busy &&
        !order.isTerminal &&
        ((order.isPacked && canMarkReady) ||
            (!order.isPacked && order.canPack && canPack && canMarkReady));

    return LayoutBuilder(builder: (context, constraints) {
      final wide =
          constraints.maxWidth >= OnlineOrderUi.tabletLandscapeBreakpoint;
      final compact = constraints.maxHeight < 720;
      final ultraCompact = constraints.maxHeight < 600;
      final header = ReviewPackHeader(
        order: order,
        onBack: widget.onBackToPickItems,
        compact: compact || ultraCompact,
      );
      final items = PickedItemsList(
        order: order,
        compact: compact || ultraCompact,
      );
      final side = ReviewPackSidebar(
        order: order,
        notesController: _notes,
        noteLength: _notes.text.characters.length,
        maxLength: packingNoteMaxLength,
        busy: _busy,
        error: _error,
        primaryEnabled: primaryEnabled,
        showPackingNote: !order.isPacked && canPack,
        onPrimary: primaryEnabled ? () => _submit(order) : null,
        onBack: widget.onBackToPickItems,
        compact: compact || ultraCompact,
        hideHelper: ultraCompact,
        bounded: wide,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          SizedBox(height: compact ? 6 : 8),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 62, child: items),
                      const SizedBox(width: 12),
                      Expanded(flex: 38, child: side),
                    ],
                  )
                : ListView(
                    children: [
                      SizedBox(height: 280, child: items),
                      const SizedBox(height: 12),
                      side,
                    ],
                  ),
          ),
        ],
      );
    });
  }

  Future<void> _submit(PosPickingOrder order) async {
    if (_busy) return;
    final note = _notes.text;
    if (note.characters.length > packingNoteMaxLength) {
      setState(() => _error =
          'Packing note must be $packingNoteMaxLength characters or fewer.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(posPickingActionsProvider(order.orderId))
          .markReadyForCollection(packingNote: note);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = mapReviewPackException(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

