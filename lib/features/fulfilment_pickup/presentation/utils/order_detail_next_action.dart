import '../../../../core/access/pos_access_codes.dart';
import '../../../../core/access/pos_permission_access.dart';
import '../../domain/entities/pos_online_order.dart';

enum OrderDetailNextAction {
  start,
  pick,
  pack,
  ready,
  readOnly,
  unavailable,
  hidden
}

/// Presentation routing only. DisplayStatus is never lifecycle authority.
OrderDetailNextAction orderDetailNextAction(
    PosOnlineOrderDetail detail, Set<String> permissions) {
  final fulfillment = detail.fulfillmentStatus?.trim().toUpperCase();
  final order = detail.orderStatus?.trim().toUpperCase();
  final pickup = detail.pickupStatus?.trim().toUpperCase();
  const terminal = {
    'CANCELLED',
    'COMPLETED',
    'COLLECTED',
    'FULFILLED',
    'VOIDED',
    'EXPIRED'
  };
  if (detail.collectedAt != null ||
      detail.completedAt != null ||
      detail.cancelledAt != null ||
      terminal.contains(order) ||
      terminal.contains(fulfillment) ||
      terminal.contains(pickup)) {
    return OrderDetailNextAction.readOnly;
  }
  if (!PosPermissionAccess.canViewOnlineOrders(permissions)) {
    return OrderDetailNextAction.hidden;
  }
  if (detail.fulfillmentOrderId?.isNotEmpty != true ||
      (detail.fulfillmentVersion ?? 0) <= 0 ||
      pickup == null ||
      detail.lines.isEmpty ||
      detail.lines.any((line) =>
          line.fulfillmentOrderLineId?.isNotEmpty != true ||
          line.authoritativeRemainingQuantity == null ||
          !line.authoritativeRemainingQuantity!.isFinite ||
          line.authoritativeRemainingQuantity! < 0)) {
    return OrderDetailNextAction.unavailable;
  }
  OrderDetailNextAction permitted(bool allowed, OrderDetailNextAction action) =>
      allowed ? action : OrderDetailNextAction.hidden;
  final remaining = detail.lines.fold<double>(
      0, (sum, line) => sum + line.authoritativeRemainingQuantity!);
  switch (fulfillment) {
    case 'PENDING':
    case 'ALLOCATED':
      if (pickup != 'PENDING') return OrderDetailNextAction.unavailable;
      return permitted(
          permissions.contains(PosPermissionCodes.startOnlineOrderFulfillment),
          OrderDetailNextAction.start);
    case 'PICKING':
      if (pickup != 'PENDING') return OrderDetailNextAction.unavailable;
      if (remaining > 0 && !detail.canPack) {
        return permitted(
            PosPermissionAccess.canViewOnlineOrderPicking(permissions),
            OrderDetailNextAction.pick);
      }
      if (remaining == 0 && detail.canPack) {
        return permitted(
            PosPermissionAccess.canViewOnlineOrderPacking(permissions),
            OrderDetailNextAction.pack);
      }
      return OrderDetailNextAction.unavailable;
    case 'PACKED':
      if (remaining != 0 || pickup != 'PENDING') {
        return OrderDetailNextAction.unavailable;
      }
      return permitted(
          PosPermissionAccess.canViewOnlineOrderPacking(permissions),
          OrderDetailNextAction.pack);
    case 'READY':
      if (!detail.isReadyForCollection ||
          detail.readyAt == null ||
          pickup != 'READY') {
        return OrderDetailNextAction.unavailable;
      }
      return permitted(PosPermissionAccess.canViewOnlineOrderReady(permissions),
          OrderDetailNextAction.ready);
    default:
      return OrderDetailNextAction.unavailable;
  }
}
