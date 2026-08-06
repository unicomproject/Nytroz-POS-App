import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/till_monitoring.dart';

class TillMonitoringRow extends StatelessWidget {
  const TillMonitoringRow({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final TillMonitoringItem item;
  final bool isSelected;
  final VoidCallback onTap;

  static const _accent = TenantAdminColors.posHomeOrangeEnd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.lg,
          vertical: TenantAdminSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? _accent.withValues(alpha: 0.06) : null,
          border: Border(
            left: BorderSide(
              color: isSelected ? _accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusBgColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.point_of_sale_rounded,
                color: _getStatusColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: TenantAdminColors.bodyText,
                    ),
                  ),
                  Text(
                    item.code,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TenantAdminColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusBadge(),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.outletName,
                style: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildCashier(),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatDate(item.lastActiveAt ?? item.lastDeviceSeenAt),
                  style: const TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            const Icon(
              Icons.chevron_right_rounded,
              color: TenantAdminColors.mutedText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashier() {
    final name = item.currentCashierName?.trim();
    final hasCashier = name != null && name.isNotEmpty && name != '-';

    if (!hasCashier) {
      return const Text(
        '—',
        style: TextStyle(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: _accent.withValues(alpha: 0.12),
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _accent,
            ),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    Color bgColor;

    switch (item.displayStatus) {
      case TillDisplayStatus.online:
        color = Colors.green.shade700;
        bgColor = Colors.green.shade50;
        text = 'ONLINE';
      case TillDisplayStatus.needsAttention:
        color = Colors.orange.shade800;
        bgColor = Colors.orange.shade50;
        text = 'NEEDS ATTENTION';
      case TillDisplayStatus.offline:
      case TillDisplayStatus.unknown:
        color = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        text = 'OFFLINE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (item.displayStatus) {
      case TillDisplayStatus.online:
        return Colors.green.shade700;
      case TillDisplayStatus.needsAttention:
        return Colors.orange.shade800;
      case TillDisplayStatus.offline:
      case TillDisplayStatus.unknown:
        return Colors.red.shade700;
    }
  }

  Color _getStatusBgColor() {
    switch (item.displayStatus) {
      case TillDisplayStatus.online:
        return Colors.green.shade50;
      case TillDisplayStatus.needsAttention:
        return Colors.orange.shade50;
      case TillDisplayStatus.offline:
      case TillDisplayStatus.unknown:
        return Colors.red.shade50;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24 && now.day == date.day) {
      return DateFormat('h:mm a').format(date);
    }
    return DateFormat('MMM d, h:mm a').format(date);
  }
}
