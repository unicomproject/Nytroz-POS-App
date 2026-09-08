import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_sales_permission_visibility.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

import 'parked_sale_cancel_dialog.dart';
import 'parked_sale_recall_dialog.dart';
import 'parked_sale_view_dialog.dart';
import 'parked_sales_formatters.dart';

class ParkedSaleCard extends ConsumerWidget {
  const ParkedSaleCard({
    super.key,
    required this.sale,
    required this.canRecall,
    required this.canCancel,
    required this.onRecallSuccess,
  });

  final PosParkedSale sale;
  final bool canRecall, canCancel;
  final PosParkedSaleRecallHandler onRecallSuccess;

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'WC';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, min(2, trimmed.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    // Reference has no independent list.* code — shown as list identity.
    final showCustomer =
        PosSalesPermissionVisibility.canShowHeldCustomer(permissions);
    final showValue =
        PosSalesPermissionVisibility.canShowHeldValue(permissions);
    final showItemCount =
        PosSalesPermissionVisibility.canShowHeldItemCount(permissions);
    final showParkedTime =
        PosSalesPermissionVisibility.canShowHeldParkedTime(permissions);
    final showExpiry =
        PosSalesPermissionVisibility.canShowHeldExpiryTime(permissions);
    final showItems =
        PosSalesPermissionVisibility.canShowHeldItems(permissions);
    final showDetails =
        PosSalesPermissionVisibility.canShowHeldDetails(permissions);

    final customerName = sale.primaryDisplayName;
    final initials = _getInitials(customerName);

    final semanticParts = <String>[
      'Parked sale ${sale.reference}',
      if (showItems) 'Items: ${sale.itemPreview}',
      if (showValue) 'Value',
      if (showCustomer) 'Customer',
    ];

    return Semantics(
      container: true,
      label: semanticParts.join('. '),
      child: Container(
        key: ValueKey('parked-sale-card-${sale.id}'),
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.article_outlined,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                const SizedBox(width: 8),
                SelectableText(
                  sale.reference,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                if (showValue)
                  Text(
                    formatMoney(sale.currency, sale.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: Color(0xFF0F172A),
                    ),
                  ),
              ],
            ),
            if (showCustomer) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        customerName == 'Walk-in customer'
                            ? 'Walk-in Customer'
                            : 'Customer',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            if (showItemCount || showParkedTime || showExpiry) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (showItemCount)
                    ParkedSaleMetaChip(
                      icon: Icons.shopping_bag_outlined,
                      label:
                          '${sale.itemCount} ${sale.itemCount == 1 ? 'item' : 'items'}',
                    ),
                  if (showParkedTime)
                    ParkedSaleBadge(
                      icon: Icons.access_time_rounded,
                      title: 'Parked ${formatTimeOnly(sale.createdAt)}',
                      subtitle: formatDateOnly(sale.createdAt),
                    ),
                  if (showExpiry && sale.expiresAt != null)
                    ParkedSaleBadge(
                      icon: Icons.timer_outlined,
                      title:
                          'Expires ${formatTimeOnly(sale.expiresAt!)} Tomorrow',
                      subtitle: formatDateOnly(sale.expiresAt!),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (showItems)
                  Expanded(
                    child: Text(
                      sale.itemPreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 8),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ParkedSaleRowActions(
                      sale: sale,
                      canRecall: canRecall,
                      canCancel: canCancel,
                      canViewDetails: showDetails,
                      onRecallSuccess: onRecallSuccess,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ParkedSaleMetaChip extends StatelessWidget {
  const ParkedSaleMetaChip({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        backgroundColor: TenantAdminColors.posHomeReturnsCard,
        side: const BorderSide(color: TenantAdminColors.posNewSaleAccent),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        avatar: Icon(
          icon,
          size: 14,
          color: TenantAdminColors.posNewSaleAccent,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.bodyText,
          ),
        ),
      );
}

class ParkedSaleBadge extends StatelessWidget {
  const ParkedSaleBadge({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5EE),
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          border: Border.all(color: const Color(0xFFFFEDD5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFEF4444)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}

class ParkedSaleRowActions extends ConsumerStatefulWidget {
  const ParkedSaleRowActions({
    super.key,
    required this.sale,
    required this.canRecall,
    required this.canCancel,
    required this.onRecallSuccess,
    this.canViewDetails = true,
  });

  final PosParkedSale sale;
  final bool canRecall, canCancel;
  final bool canViewDetails;
  final PosParkedSaleRecallHandler onRecallSuccess;

  @override
  ConsumerState<ParkedSaleRowActions> createState() =>
      _ParkedSaleRowActionsState();
}

class _ParkedSaleRowActionsState extends ConsumerState<ParkedSaleRowActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.canViewDetails)
              OutlinedButton.icon(
                key: ValueKey('view-${widget.sale.id}'),
                onPressed: _busy ? null : _handleView,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(
                      color: TenantAdminColors.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  ),
                ),
              ),
            if (widget.canCancel) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: ValueKey('cancel-${widget.sale.id}'),
                onPressed: _busy ? null : _handleCancel,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
                label: const Text(
                  'Cancel Parked Sale',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  foregroundColor: const Color(0xFFEF4444),
                  side: BorderSide(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  ),
                ),
              ),
            ],
            if (widget.canRecall) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                key: ValueKey('recall-${widget.sale.id}'),
                onPressed: _busy ? null : _handleRecall,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  backgroundColor: TenantAdminColors.posNewSaleAccent,
                  foregroundColor: TenantAdminColors.surface,
                  elevation: 1,
                ),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text(
                  'Recall',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      );

  Future<void> _handleView() async {
    if (!widget.canViewDetails) return;
    await showParkedSaleViewDialog(context, widget.sale);
  }

  Future<void> _handleCancel() async {
    if (!widget.canCancel || _busy) return;
    setState(() => _busy = true);
    try {
      await showParkedSaleCancelDialog(context, ref, widget.sale);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleRecall() async {
    if (!widget.canRecall || _busy) return;
    setState(() => _busy = true);
    try {
      await beginParkedSaleRecall(
        context,
        ref,
        widget.sale,
        widget.onRecallSuccess,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
