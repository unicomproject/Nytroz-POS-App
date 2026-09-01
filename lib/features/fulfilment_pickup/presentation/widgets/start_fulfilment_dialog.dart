import 'package:flutter/material.dart';

import '../../../../shared/presentation/app_modal.dart';
import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/pos_online_order.dart';
import 'online_order_ui.dart';

class StartFulfilmentDialog extends StatefulWidget {
  const StartFulfilmentDialog({
    required this.detail,
    required this.onConfirm,
    super.key,
  });

  final PosOnlineOrderDetail detail;
  final Future<bool> Function() onConfirm;

  static Future<bool> show(
    BuildContext context,
    PosOnlineOrderDetail detail, {
    required Future<bool> Function() onConfirm,
  }) async {
    final compact =
        MediaQuery.sizeOf(context).width < OnlineOrderUi.phoneBreakpoint;
    if (compact) {
      return await showAppModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            showDragHandle: false,
            isDismissible: false,
            enableDrag: false,
            builder: (_) => SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  TenantAdminSpacing.lg,
                  TenantAdminSpacing.lg,
                  TenantAdminSpacing.lg,
                  TenantAdminSpacing.lg +
                      MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: StartFulfilmentDialog(
                  detail: detail,
                  onConfirm: onConfirm,
                ),
              ),
            ),
          ) ??
          false;
    }
    return await showAppDialog<bool>(
          context: context,
          barrierDismissible: false,
          barrierLabel: 'Start fulfilment confirmation',
          builder: (_) => Dialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(TenantAdminSpacing.xlg),
                child: StartFulfilmentDialog(
                  detail: detail,
                  onConfirm: onConfirm,
                ),
              ),
            ),
          ),
        ) ??
        false;
  }

  @override
  State<StartFulfilmentDialog> createState() => _StartFulfilmentDialogState();
}

class _StartFulfilmentDialogState extends State<StartFulfilmentDialog> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final urgency = _relativeCollectionTime(detail);
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Semantics(
      namesRoute: true,
      label: 'Start fulfilment confirmation',
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FulfilmentDialogIcon(compact: compact),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'Start Fulfilment?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'You are about to start picking this order.\n'
            'This order will be assigned to you.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _FulfilmentOrderSummary(
            detail: detail,
            urgency: urgency,
            quantity: _quantity(detail.unitCount),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          PosPrimaryActionButton(
            key: const Key('oo03-confirm-start'),
            label: 'Yes, Start Fulfilment',
            semanticLabel: 'Yes, Start Fulfilment',
            leadingIcon: Icons.play_arrow_rounded,
            onPressed: _isSubmitting ? null : _confirm,
            isLoading: _isSubmitting,
            fullWidth: true,
            compact: true,
            backgroundColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          PosBottomOutlinedButton(
            label: 'Cancel',
            icon: Icons.close_rounded,
            onPressed:
                _isSubmitting ? null : () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final succeeded = await widget.onConfirm();
    if (!mounted) return;
    Navigator.pop(context, succeeded);
  }

  String? _relativeCollectionTime(PosOnlineOrderDetail detail) {
    final collection = detail.order.collectionAt;
    final server = detail.serverTime;
    if (collection == null || server == null) return null;
    final difference = collection.difference(server);
    final duration = difference.abs();
    final text = '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    return difference.isNegative ? 'Overdue by $text' : '$text remaining';
  }

  String _quantity(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

class _FulfilmentDialogIcon extends StatelessWidget {
  const _FulfilmentDialogIcon({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final diameter = compact ? 52.0 : 58.0;
    return Align(
      alignment: Alignment.center,
      child: Container(
        key: const Key('oo03-dialog-icon'),
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          size: compact ? 25 : 28,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _FulfilmentOrderSummary extends StatelessWidget {
  const _FulfilmentOrderSummary({
    required this.detail,
    required this.urgency,
    required this.quantity,
  });

  final PosOnlineOrderDetail detail;
  final String? urgency;
  final String quantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('oo03-summary-card'),
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FulfilmentSummaryRow(
            icon: Icons.inventory_2_outlined,
            label: 'Order',
            value: detail.order.orderNumber,
          ),
          _FulfilmentSummaryRow(
            icon: Icons.person_outline_rounded,
            label: 'Customer',
            value: detail.order.customerName,
          ),
          _FulfilmentSummaryRow(
            icon: Icons.location_on_outlined,
            label: 'Collection',
            value: detail.outletName,
          ),
          _FulfilmentSummaryRow(
            icon: Icons.schedule_outlined,
            label: 'Collect by',
            value: [
              OnlineOrderUi.collection(detail.order.collectionAt),
              if (urgency != null) urgency!,
            ].join('\n'),
            emphasisColor: urgency == null
                ? null
                : urgency!.startsWith('Overdue')
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
          ),
          _FulfilmentSummaryRow(
            icon: Icons.view_in_ar_outlined,
            label: 'Items',
            value: '${detail.itemCount} items • $quantity units',
          ),
        ],
      ),
    );
  }
}

class _FulfilmentSummaryRow extends StatelessWidget {
  const _FulfilmentSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasisColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? emphasisColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: PosPrimaryActionTokens.iconSize,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            flex: 2,
            child: Semantics(
              label: '$label: $value',
              child: ExcludeSemantics(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: emphasisColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
