import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import '../widgets/online_order_ui.dart';
import '../widgets/picking/pick_item_barcode_entry_dialog.dart';
import '../widgets/picking/pick_item_workspace.dart';
import '../widgets/picking/report_picking_issue_dialog.dart';

class PosPickItemScreen extends ConsumerStatefulWidget {
  const PosPickItemScreen({
    required this.orderId,
    required this.lineId,
    super.key,
  });

  final String orderId;
  final String lineId;

  @override
  ConsumerState<PosPickItemScreen> createState() => _PosPickItemScreenState();
}

class _PosPickItemScreenState extends ConsumerState<PosPickItemScreen> {
  String? _verifiedBarcode;
  bool _verifiedByScan = true;
  int _quantity = 1;
  bool _submitting = false;
  String? _message;
  bool _isError = false;

  @override
  void didUpdateWidget(covariant PosPickItemScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId ||
        oldWidget.lineId != widget.lineId) {
      _resetInput();
      ref.invalidate(posPickingOrderProvider(oldWidget.orderId));
    }
  }

  void _resetInput() {
    _verifiedBarcode = null;
    _verifiedByScan = true;
    _quantity = 1;
    _message = null;
    _isError = false;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final permissions = session?.permissionCodes.toSet() ?? const <String>{};
    final canView =
        permissions.contains(PosPermissionCodes.accessOnlineOrders) &&
            permissions.contains(PosPermissionCodes.viewOnlineOrders) &&
            permissions.contains(PosPermissionCodes.viewOnlineOrderPicking);
    if (!canView) {
      return const ColoredBox(
        color: OnlineOrderUi.canvas,
        child: OnlineOrderScreenState(
          message: 'You do not have permission to access order picking.',
          icon: Icons.lock_outline,
        ),
      );
    }

    return ColoredBox(
      color: OnlineOrderUi.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: ref.watch(posPickingOrderProvider(widget.orderId)).when(
              loading: () => const OnlineOrderScreenState(
                message: 'Loading item picking workspace…',
                icon: Icons.hourglass_top,
              ),
              error: (_, __) => OnlineOrderScreenState(
                message: 'Unable to load this picking item.',
                icon: Icons.error_outline,
                onRetry: () =>
                    ref.invalidate(posPickingOrderProvider(widget.orderId)),
              ),
              data: (order) => _content(context, order, permissions),
            ),
      ),
    );
  }

  Widget _content(
      BuildContext context, PosPickingOrder order, Set<String> permissions) {
    PosPickingLine? line;
    for (final candidate in order.lines) {
      if (candidate.id == widget.lineId) {
        line = candidate;
        break;
      }
    }
    if (line == null) {
      return OnlineOrderScreenState(
        message: 'This picking item is no longer available.',
        icon: Icons.inventory_2_outlined,
        onRetry: () =>
            context.go('/pos/online-orders/${widget.orderId}/picking'),
      );
    }

    final canPick =
        permissions.contains(PosPermissionCodes.pickOnlineOrderItem);
    final canScan =
        canPick && permissions.contains(PosPermissionCodes.scanOnlineOrderItem);
    final canManual = canPick &&
        permissions.contains(PosPermissionCodes.manuallyEnterOnlineOrderItem);
    final canReport =
        permissions.contains(PosPermissionCodes.reportOnlineOrderPickingIssue);
    final maxQuantity = line.remainingQuantity.floor();
    final quantity = _quantity.clamp(1, maxQuantity < 1 ? 1 : maxQuantity);

    return PickItemWorkspace(
      key: ValueKey('${order.orderId}:${line.id}:${order.fulfillmentVersion}'),
      order: order,
      line: line,
      quantity: quantity,
      verifiedBarcode: _verifiedBarcode,
      verificationMessage: _message,
      verificationIsError: _isError,
      isSubmitting: _submitting,
      canScan: canScan,
      canManual: canManual,
      canPick: canPick,
      canReport: canReport,
      onBack: () => context.go('/pos/online-orders/${widget.orderId}/picking'),
      onScan: canScan ? () => _captureBarcode(line!, scanned: true) : null,
      onManual: canManual ? () => _captureBarcode(line!, scanned: false) : null,
      onDecrease: quantity > 1 ? () => setState(() => _quantity--) : null,
      onIncrease:
          quantity < maxQuantity ? () => setState(() => _quantity++) : null,
      onPick: canPick && !line.isPicked && _verifiedBarcode != null
          ? () => _pick(order, line!, quantity)
          : null,
      onIssue: canReport ? () => _reportIssue(order, line!) : null,
      onSelectLine: (nextLine) => context.go(
          '/pos/online-orders/${widget.orderId}/picking/lines/${nextLine.id}'),
      onReviewPack: order.canPack
          ? () => context.go('/pos/online-orders/${widget.orderId}/picking')
          : null,
    );
  }

  Future<void> _captureBarcode(PosPickingLine line,
      {required bool scanned}) async {
    // Dialog owns TextEditingController lifecycle. Do not dispose a caller-
    // owned controller after showDialog returns — the TextField remains
    // mounted during the exit animation and that race causes
    // InheritedElement `_dependents.isEmpty` assertions.
    final value = await PickItemBarcodeEntryDialog.show(
      context,
      scanned: scanned,
    );
    if (!mounted || value == null) return;
    final normalized = value.trim();
    final authority = line.barcode?.trim();
    if (normalized.isEmpty ||
        authority == null ||
        authority.isEmpty ||
        normalized.toLowerCase() != authority.toLowerCase()) {
      setState(() {
        _verifiedBarcode = null;
        _message = 'Barcode does not match the selected item.';
        _isError = true;
      });
      return;
    }
    setState(() {
      _verifiedBarcode = normalized;
      _verifiedByScan = scanned;
      _message = 'Barcode verified. Confirm the quantity to continue.';
      _isError = false;
    });
  }

  Future<void> _pick(
      PosPickingOrder order, PosPickingLine line, int quantity) async {
    if (_submitting || _verifiedBarcode == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(posPickingActionsProvider(widget.orderId)).pick(
            order,
            line,
            scanned: _verifiedByScan,
            barcode: _verifiedBarcode!,
            quantity: quantity.toDouble(),
          );
      if (!mounted) return;
      setState(_resetInput);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = onlineOrderErrorMessage(error);
        _isError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Unable to complete the picking action. Try again.';
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _reportIssue(PosPickingOrder order, PosPickingLine line) async {
    final note = await ReportPickingIssueDialog.show(context, line);
    if (note == null || !mounted) return;
    try {
      await ref
          .read(posPickingActionsProvider(widget.orderId))
          .issue(order, line, 'ITEM_NOT_FOUND', note);
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(onlineOrderErrorMessage(error))));
    }
  }
}
