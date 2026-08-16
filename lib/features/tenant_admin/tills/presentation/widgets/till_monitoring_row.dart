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

  static const _accent = TenantAdminColors.posHomeAccentOrange;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        return Semantics(
          button: true,
          selected: isSelected,
          label: 'Till ${item.name}',
          child: InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal:
                    compact ? TenantAdminSpacing.md : TenantAdminSpacing.lg,
                vertical: compact ? 12 : TenantAdminSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isSelected ? _accent.withValues(alpha: 0.06) : null,
                border: Border(
                  left: BorderSide(
                    color: isSelected ? _accent : Colors.transparent,
                    width: isSelected ? 4 : 0,
                  ),
                ),
              ),
              child: compact ? _buildCompactContent() : _buildDesktopContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopContent() {
    return Row(
      children: [
        _buildTillIcon(size: 40),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(flex: 2, child: _buildTitleBlock()),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(flex: 2, child: _buildCashier()),
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildLastActivityText(),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        const Icon(
          Icons.chevron_right_rounded,
          color: TenantAdminColors.mutedText,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildCompactContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTillIcon(size: 38),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(child: _buildTitleBlock()),
            const SizedBox(width: TenantAdminSpacing.sm),
            Flexible(
                child: Align(
                    alignment: Alignment.topRight, child: _buildStatusBadge())),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Wrap(
          spacing: TenantAdminSpacing.lg,
          runSpacing: TenantAdminSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _CompactMeta(
              icon: Icons.storefront_outlined,
              child: Text(
                item.outletName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _CompactMeta(
              icon: Icons.person_outline,
              child: _buildCashier(compact: true),
            ),
            _CompactMeta(
              icon: Icons.schedule_outlined,
              child: _buildLastActivityText(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTillIcon({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getStatusBgColor(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.point_of_sale_rounded,
        color: _getStatusColor(),
        size: 20,
      ),
    );
  }

  Widget _buildTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: TenantAdminColors.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCashier({bool compact = false}) {
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
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        CircleAvatar(
          radius: compact ? 10 : 12,
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
        Flexible(
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
        text = 'Online';
      case TillDisplayStatus.needsAttention:
        color = Colors.orange.shade800;
        bgColor = Colors.orange.shade50;
        text = 'Needs Attention';
      case TillDisplayStatus.offline:
      case TillDisplayStatus.unknown:
        color = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        text = 'Offline';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLastActivityText() {
    return Text(
      _formatDate(item.lastActiveAt ?? item.lastDeviceSeenAt),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: TenantAdminColors.mutedText,
        fontSize: 13,
        fontWeight: FontWeight.w500,
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

class _CompactMeta extends StatelessWidget {
  const _CompactMeta({
    required this.icon,
    required this.child,
  });

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TenantAdminColors.mutedText),
          const SizedBox(width: 5),
          Flexible(
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
