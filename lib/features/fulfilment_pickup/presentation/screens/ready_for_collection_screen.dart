import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../sale/presentation/widgets/new_sale/pos_camera_barcode_scanner.dart'
    show PosCameraScanResultType;
import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import '../utils/picking_formatters.dart';
import '../utils/picking_visual_metrics.dart';
import '../widgets/online_order_ui.dart';
import '../widgets/picking/picking_progress_metrics.dart';

class ReadyForCollectionScreen extends ConsumerStatefulWidget {
  const ReadyForCollectionScreen({
    required this.order,
    required this.onBack,
    this.onBackToReviewPack,
    super.key,
  });

  final PosPickingOrder order;
  final VoidCallback onBack;
  final VoidCallback? onBackToReviewPack;

  @override
  ConsumerState<ReadyForCollectionScreen> createState() =>
      _ReadyForCollectionScreenState();
}

class _ReadyForCollectionScreenState
    extends ConsumerState<ReadyForCollectionScreen> {
  bool _busy = false;
  bool _scannerOpening = false;
  String? _error;
  String? _success;

  @override
  Widget build(BuildContext context) {
    final order =
        ref.watch(posPickingOrderProvider(widget.order.orderId)).maybeWhen(
              data: (value) => value,
              orElse: () => widget.order,
            );
    final granted =
        ref.watch(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    final canViewReady = PosPermissionAccess.canViewOnlineOrderReady(granted);
    final canNotify =
        PosPermissionAccess.canNotifyOnlineOrderCustomer(granted);
    final canVerify = PosPermissionAccess.canVerifyOnlineOrderPickup(granted);
    final canComplete =
        PosPermissionAccess.canCompleteOnlineOrderCollection(granted);

    if (!canViewReady) {
      return const OnlineOrderScreenState(
        message: 'Ready-for-collection permission is required.',
        icon: Icons.lock_outline,
      );
    }

    if (order.isCollected ||
        (order.isTerminal && !order.isReadyForCollection)) {
      return OnlineOrderScreenState(
        message: order.status.toUpperCase() == 'CANCELLED'
            ? 'This order was cancelled.'
            : 'This order has already been collected or completed.',
        icon: Icons.inventory_2_outlined,
        onRetry: widget.onBack,
      );
    }

    if (!order.isReadyForCollection) {
      return OnlineOrderScreenState(
        message: order.isPacked
            ? 'This order is packed but not ready yet.'
            : 'This order is not ready for collection yet.',
        icon: Icons.info_outline,
        onRetry: () =>
            ref.invalidate(posPickingOrderProvider(widget.order.orderId)),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final wide =
          constraints.maxWidth >= OnlineOrderUi.tabletLandscapeBreakpoint;
      final compact = !wide || constraints.maxHeight < 720;
      final ultraCompact = constraints.maxHeight < 600;
      final header = _ReadyHeader(
        order: order,
        compact: compact || ultraCompact,
        onBack: widget.onBackToReviewPack ?? widget.onBack,
      );
      final left = _ReadyLeftColumn(
        order: order,
        compact: compact || ultraCompact,
        ultraCompact: ultraCompact,
        canNotify: canNotify,
        canVerify: canVerify,
        canComplete: canComplete,
        busy: _busy,
        scanning: _scannerOpening,
        error: _error,
        success: _success,
        onNotify: canNotify && !_busy
            ? () => unawaited(_notify(order))
            : null,
        onVerify: canVerify && !_busy && !_scannerOpening
            ? () => unawaited(_verify(order))
            : null,
        onComplete: canComplete && !_busy
            ? () => unawaited(_complete(order))
            : null,
      );
      final right = _ReadyRightColumn(
        order: order,
        compact: compact || ultraCompact,
        ultraCompact: ultraCompact,
        onViewDetails: () =>
            context.go('/pos/online-orders/${order.orderId}'),
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
                      Expanded(flex: 58, child: left),
                      const SizedBox(width: 12),
                      Expanded(flex: 42, child: right),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Stacked cards need their own content budget, not the
                        // compressed landscape height. Keep both reachable.
                        SizedBox(height: 600, child: left),
                        const SizedBox(height: 12),
                        SizedBox(height: 600, child: right),
                      ],
                    ),
                  ),
          ),
        ],
      );
    });
  }

  Future<void> _notify(PosPickingOrder order) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      final result = await ref
          .read(posPickingActionsProvider(order.orderId))
          .notifyCustomerOrderReady();
      if (!mounted) return;
      setState(() {
        _success = result.alreadyExisted
            ? 'Customer was already notified for this order.'
            : 'Customer notified that the order is ready.';
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _error = _mapError(error));
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _error = 'Unable to notify the customer for this order.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapError(DioException error) {
    final code = error.response?.data is Map
        ? (error.response!.data as Map)['errorCode']?.toString()
        : null;
    return switch (code) {
      'online_orders.notification_recipient_unavailable' =>
        'Customer notification is unavailable for this order.',
      'online_orders.permission_denied' =>
        'You do not have permission to notify the customer.',
      'online_orders.concurrency_conflict' =>
        'This order changed. Refresh and try again.',
      'online_orders.invalid_state' =>
        'This order is not ready for customer notification.',
      _ => error.response?.statusCode == 403
          ? 'You do not have permission to notify the customer.'
          : error.response?.statusCode == 404
              ? 'This order could not be found.'
              : 'Unable to notify the customer for this order.',
    };
  }

  Future<void> _verify(PosPickingOrder order) async {
    if (_busy || _scannerOpening) return;
    setState(() => _scannerOpening = true);
    try {
      final launch = ref.read(posPickupScannerLauncherProvider);
      final result = await launch(
        context,
        formats: const [BarcodeFormat.qrCode],
        instructionText: "Scan the customer's pickup QR code",
      );
      if (!mounted) return;
      if (result.type != PosCameraScanResultType.barcode) {
        final message = switch (result.type) {
          PosCameraScanResultType.permissionDenied =>
            'Camera access is disabled. Enable it in system settings.',
          PosCameraScanResultType.unavailable =>
            'No camera is available on this device.',
          PosCameraScanResultType.failed =>
            'Unable to start the camera scanner.',
          PosCameraScanResultType.unsupported =>
            'Camera scanning is unavailable on this device.',
          _ => null,
        };
        if (message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
        return;
      }
      final pickupCode = _extractPickupCode(result.barcode);
      if (pickupCode == null) {
        setState(() =>
            _error = 'This QR code is not a valid pickup code.');
        return;
      }
      await _submitVerify(order, pickupCode);
    } finally {
      if (mounted) setState(() => _scannerOpening = false);
    }
  }

  /// The customer's QR encodes `CLICK_COLLECT:{tenantId}:{orderId}:{code}` —
  /// only the trailing secret code is sent for verification.
  static String? _extractPickupCode(String? scanned) {
    final value = scanned?.trim();
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 4 || parts[0] != 'CLICK_COLLECT') return null;
    final code = parts[3].trim();
    return code.isEmpty ? null : code;
  }

  Future<void> _submitVerify(PosPickingOrder order, String pickupCode) async {
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      await ref
          .read(posPickingActionsProvider(order.orderId))
          .verifyPickupCode(pickupCode);
      if (!mounted) return;
      setState(() =>
          _success = 'Pickup code verified. You can now complete the order.');
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _error = _mapPickupError(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to verify this pickup code.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete(PosPickingOrder order) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      await ref
          .read(posPickingActionsProvider(order.orderId))
          .completeCollection();
      if (!mounted) return;
      setState(() => _success = 'Order marked as collected.');
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _error = _mapPickupError(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to mark this order as collected.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapPickupError(DioException error) {
    final data = error.response?.data;
    final code = data is Map ? data['errorCode']?.toString() : null;
    final serverMessage = data is Map ? data['message']?.toString() : null;
    return switch (code) {
      'online_orders.pickup_code_expired' =>
        'This pickup code has expired. Ask the customer to refresh their order for a new one.',
      'online_orders.pickup_code_mismatch' =>
        (serverMessage != null && serverMessage.isNotEmpty)
            ? serverMessage
            : 'The pickup code does not match this order.',
      'online_orders.pickup_verification_locked' =>
        'Too many failed attempts. This pickup code is locked — a new one must be issued.',
      'online_orders.invalid_state' =>
        'This order is not in the right state for this action.',
      'online_orders.permission_denied' =>
        'You do not have permission to do this.',
      'online_orders.not_found' => 'This order could not be found.',
      _ => error.response?.statusCode == 403
          ? 'You do not have permission to do this.'
          : error.response?.statusCode == 404
              ? 'This order could not be found.'
              : 'Unable to complete this action.',
    };
  }
}

class _ReadyHeader extends StatelessWidget {
  const _ReadyHeader({
    required this.order,
    required this.compact,
    this.onBack,
  });

  final PosPickingOrder order;
  final bool compact;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 28,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: 'Back to Review and Pack',
              child: TextButton.icon(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.arrow_back, size: 17),
                label: const Text(
                  'Back to Review & Pack',
                  style: TextStyle(fontSize: 13.5),
                ),
              ),
            ),
          ),
        ),
        LayoutBuilder(builder: (context, constraints) {
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Ready for Collection',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: compact ? 20 : 23,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '3 of 3',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(
                'Finalize the order and confirm it is ready for customer collection.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OnlineOrderUi.subtitle.copyWith(fontSize: 13),
              ),
            ],
          );
          final metrics =
              PickingProgressMetrics(order: order, compact: compact);
          if (constraints.maxWidth >= 900) {
            return Row(children: [
              Expanded(flex: 52, child: title),
              const SizedBox(width: 12),
              Expanded(flex: 48, child: metrics),
            ]);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              SizedBox(height: compact ? 6 : 8),
              metrics,
            ],
          );
        }),
      ],
    );
  }
}

class _ReadyLeftColumn extends StatelessWidget {
  const _ReadyLeftColumn({
    required this.order,
    required this.compact,
    required this.ultraCompact,
    required this.canNotify,
    required this.canVerify,
    required this.canComplete,
    required this.busy,
    required this.scanning,
    this.error,
    this.success,
    this.onNotify,
    this.onVerify,
    this.onComplete,
  });

  final PosPickingOrder order;
  final bool compact;
  final bool ultraCompact;
  final bool canNotify;
  final bool canVerify;
  final bool canComplete;
  final bool busy;
  final bool scanning;
  final String? error;
  final String? success;
  final VoidCallback? onNotify;
  final VoidCallback? onVerify;
  final VoidCallback? onComplete;

  bool get _isVerified => order.pickupStatus?.toUpperCase() == 'VERIFIED';

  @override
  Widget build(BuildContext context) {
    final successTone = Colors.green.shade700;
    final gap = ultraCompact ? 6.0 : (compact ? 8.0 : 10.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: ultraCompact ? 4 : 5,
          child: ReadyForCollectionHero(
            order: order,
            compact: compact || ultraCompact,
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          flex: ultraCompact ? 5 : 6,
          child: _WhatsNextCard(compact: compact || ultraCompact),
        ),
        SizedBox(height: gap),
        if (error != null)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: Text(
              error!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        if (success != null)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: Text(
              success!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: successTone,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        if (canNotify)
          SizedBox(
            height: ultraCompact ? 36 : (compact ? 40 : 44),
            child: PosPrimaryActionButton(
              key: const Key('notify-customer-order-ready'),
              label: order.hasReadyNotification
                  ? 'Customer Already Notified'
                  : 'Notify Customer Order is Ready',
              fullWidth: true,
              compact: true,
              isLoading: busy,
              minimumHeight: ultraCompact ? 36 : (compact ? 40 : 44),
              verticalPadding: 0,
              backgroundColor: Theme.of(context).colorScheme.primary,
              gradient: null,
              semanticLabel: 'Notify Customer Order is Ready',
              onPressed: onNotify,
              leadingIcon: Icons.notifications_active_outlined,
            ),
          ),
        if (_isVerified)
          Padding(
            padding: EdgeInsets.only(top: gap),
            child: SizedBox(
              height: ultraCompact ? 36 : (compact ? 40 : 44),
              child: canComplete
                  ? PosPrimaryActionButton(
                      key: const Key('complete-order-collection'),
                      label: 'Complete Order',
                      fullWidth: true,
                      compact: true,
                      isLoading: busy,
                      minimumHeight: ultraCompact ? 36 : (compact ? 40 : 44),
                      verticalPadding: 0,
                      backgroundColor: Colors.green.shade700,
                      gradient: null,
                      semanticLabel: 'Complete Order',
                      onPressed: onComplete,
                      leadingIcon: Icons.inventory_2_outlined,
                    )
                  : const _PickupStatusBanner(
                      icon: Icons.verified_outlined,
                      label: 'Pickup code verified',
                    ),
            ),
          )
        else if (canVerify)
          Padding(
            padding: EdgeInsets.only(top: gap),
            child: SizedBox(
              height: ultraCompact ? 36 : (compact ? 40 : 44),
              child: PosPrimaryActionButton(
                key: const Key('scan-verify-pickup-code'),
                label: 'Scan to Verify Collection',
                fullWidth: true,
                compact: true,
                isLoading: scanning || busy,
                minimumHeight: ultraCompact ? 36 : (compact ? 40 : 44),
                verticalPadding: 0,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                gradient: null,
                semanticLabel: 'Scan to Verify Collection',
                onPressed: onVerify,
                leadingIcon: Icons.qr_code_scanner_outlined,
              ),
            ),
          ),
        if (!ultraCompact) ...[
          SizedBox(height: gap),
          Text(
            'You can also notify the customer later from the Orders list.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: OnlineOrderUi.subtitle.copyWith(fontSize: 11.5),
          ),
        ],
      ],
    );
  }
}

class _PickupStatusBanner extends StatelessWidget {
  const _PickupStatusBanner({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tone = Colors.green.shade700;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: tone, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class ReadyForCollectionHero extends StatelessWidget {
  const ReadyForCollectionHero({
    required this.order,
    this.compact = false,
    this.onBack,
    super.key,
  });

  final PosPickingOrder order;
  final bool compact;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final successTone = Colors.green.shade700;
    return Semantics(
      label: 'All items picked and packed. This order is ready for customer collection.',
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 18),
        decoration: pickingCardDecoration(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: compact ? 28 : 36,
              backgroundColor: successTone.withValues(alpha: .12),
              child: Icon(Icons.check, color: successTone, size: compact ? 32 : 42),
            ),
            SizedBox(height: compact ? 10 : 14),
            Text(
              'All items picked and packed!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This order is ready for customer collection.',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: OnlineOrderUi.subtitle.copyWith(fontSize: compact ? 12.5 : 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsNextCard extends StatelessWidget {
  const _WhatsNextCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const steps = [
      (
        Icons.shopping_bag_outlined,
        'Customer Collection',
        'Notify the customer that their order is ready.'
      ),
      (
        Icons.fact_check_outlined,
        'Verify Collection',
        'Confirm customer details when they arrive.'
      ),
      (
        Icons.inventory_2_outlined,
        'Complete Order',
        'Mark the order as collected to close it.'
      ),
    ];
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: pickingCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "What's next?",
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0) SizedBox(width: compact ? 6 : 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: compact ? 16 : 18,
                          backgroundColor: primary.withValues(alpha: .1),
                          child: Icon(steps[i].$1, color: primary, size: 18),
                        ),
                        SizedBox(height: compact ? 6 : 8),
                        Text(
                          steps[i].$2,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 11 : 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          steps[i].$3,
                          textAlign: TextAlign.center,
                          maxLines: compact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: OnlineOrderUi.subtitle.copyWith(
                            fontSize: compact ? 10 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyRightColumn extends StatelessWidget {
  const _ReadyRightColumn({
    required this.order,
    required this.compact,
    required this.ultraCompact,
    required this.onViewDetails,
  });

  final PosPickingOrder order;
  final bool compact;
  final bool ultraCompact;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final gap = ultraCompact ? 6.0 : 8.0;
    final pending =
        (order.totalLines - order.pickedLines).clamp(0, order.totalLines);
    final issues = order.issueCount > 0
        ? order.issueCount
        : order.lines.where((line) => line.hasReportedIssue).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: ReadyOrderSummary(order: order, compact: true),
        ),
        SizedBox(height: gap),
        Expanded(
          flex: 4,
          child: _ReadyProgressCard(
            order: order,
            pending: pending,
            issues: issues,
            compact: true,
          ),
        ),
        SizedBox(height: gap),
        SizedBox(
          height: ultraCompact ? 32 : 36,
          child: OutlinedButton.icon(
            key: const Key('view-order-details'),
            onPressed: onViewDetails,
            icon: const Icon(Icons.description_outlined, size: 16),
            label: const Text('View Order Details'),
          ),
        ),
      ],
    );
  }
}

class ReadyOrderSummary extends StatelessWidget {
  const ReadyOrderSummary({
    required this.order,
    this.compact = false,
    super.key,
  });

  final PosPickingOrder order;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final urgency = pickingUrgency(order.collectionAt, order.serverTime);
    final remainingLabel = urgency.shortLabel == 'Not set'
        ? null
        : urgency.isOverdue
            ? '${urgency.shortLabel} overdue'
            : '${urgency.shortLabel} remaining';
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: pickingCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _summaryRow(
                        context,
                        'Order',
                        '#${order.orderNumber}',
                        trailing: OnlineOrderStatusChip(
                          label: 'Ready for Collection',
                          status: 'READY',
                        ),
                      ),
                      _summaryRow(
                        context,
                        'Customer',
                        order.customerName.trim().isEmpty
                            ? 'Customer unavailable'
                            : order.customerName,
                      ),
                      _summaryRow(
                        context,
                        'Outlet',
                        order.outletName?.trim().isNotEmpty == true
                            ? order.outletName!
                            : 'Collection outlet',
                      ),
                      _summaryRow(
                        context,
                        'Collection',
                        order.collectionAt == null
                            ? 'Not scheduled'
                            : DateFormat('dd MMM, hh:mm a')
                                .format(order.collectionAt!.toLocal()),
                      ),
                      if (remainingLabel != null)
                        _summaryRow(
                          context,
                          urgency.isOverdue ? 'Overdue' : 'Remaining',
                          remainingLabel,
                          valueColor: urgency.isOverdue
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    Widget? trailing,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OnlineOrderUi.subtitle.copyWith(fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: valueColor,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing,
          ],
        ],
      ),
    );
  }
}

class _ReadyProgressCard extends StatelessWidget {
  const _ReadyProgressCard({
    required this.order,
    required this.pending,
    required this.issues,
    required this.compact,
  });

  final PosPickingOrder order;
  final int pending;
  final int issues;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final successTone = Colors.green.shade700;
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: pickingCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Order Progress',
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Semantics(
                  label:
                      'Order progress ${order.pickedLines} of ${order.totalLines} picked',
                  child: SizedBox.square(
                    dimension: compact ? 52 : 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: order.totalLines == 0
                              ? 0
                              : order.pickedLines / order.totalLines,
                          strokeWidth: 5,
                          backgroundColor: Theme.of(context).dividerColor,
                          color: successTone,
                        ),
                        Text(
                          '${order.pickedLines}/${order.totalLines}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legend('Picked', order.pickedLines, successTone),
                      _legend(
                        'Pending',
                        pending,
                        Theme.of(context).colorScheme.primary,
                      ),
                      _legend(
                        'Issues',
                        issues,
                        Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: successTone.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Order is ready for collection! Waiting for customer to collect their order.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: successTone,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, int value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$value',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}
