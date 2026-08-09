import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final customerName = sale.primaryDisplayName;
    final initials = _getInitials(customerName);

    return Semantics(
      container: true,
      label: 'Parked sale ${sale.reference}. Items: ${sale.itemPreview}',
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
            // Row 1: Document icon + Reference ... Amount
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
            const SizedBox(height: 10),

            // Row 2: Customer Circle + Name + Subtitle
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
            const SizedBox(height: 12),

            // Row 3: Metadata Badges (Items, Parked Time, Expires Time)
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ParkedSaleMetaChip(
                  icon: Icons.shopping_bag_outlined,
                  label:
                      '${sale.itemCount} ${sale.itemCount == 1 ? 'item' : 'items'}',
                ),
                ParkedSaleBadge(
                  icon: Icons.access_time_rounded,
                  title: 'Parked ${formatTimeOnly(sale.createdAt)}',
                  subtitle: formatDateOnly(sale.createdAt),
                ),
                if (sale.expiresAt != null)
                  ParkedSaleBadge(
                    icon: Icons.timer_outlined,
                    title:
                        'Expires ${formatTimeOnly(sale.expiresAt!)} Tomorrow',
                    subtitle: formatDateOnly(sale.expiresAt!),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 4: Item Preview Text (Left) & Action Buttons (Right)
            Row(
              children: [
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
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ParkedSaleRowActions(
                      sale: sale,
                      canRecall: canRecall,
                      canCancel: canCancel,
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
  });

  final PosParkedSale sale;
  final bool canRecall, canCancel;
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  ),
                ),
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text(
                  'Recall Sale',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Future<void> _handleRecall() => _guard(() =>
      beginParkedSaleRecall(context, ref, widget.sale, widget.onRecallSuccess));

  Future<void> _handleView() =>
      _guard(() => showParkedSaleViewDialog(context, widget.sale));

  Future<void> _handleCancel() =>
      _guard(() => showParkedSaleCancelDialog(context, ref, widget.sale));

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
