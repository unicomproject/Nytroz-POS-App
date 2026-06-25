import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/tenant_dashboard.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';

class NeedsAttentionCard extends StatelessWidget {
  const NeedsAttentionCard({
    super.key,
    required this.items,
    this.showViewAll = false,
  });

  final List<TenantDashboardAttentionItem> items;
  final bool showViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Needs attention',
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
              ),
              if (showViewAll)
                TextButton(
                  onPressed: () {},
                  child: const Text('View all'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              'No attention items right now.',
              style: TenantAdminTextStyles.muted(context),
            )
          else
            for (var index = 0; index < items.length; index++) ...[
              _AttentionTile(item: items[index]),
              if (index != items.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.item});

  final TenantDashboardAttentionItem item;

  @override
  Widget build(BuildContext context) {
    final status = _statusType(item.status);
    final color = _colorFor(status);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(status), color: color, size: 20),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          const Icon(
            Icons.chevron_right,
            color: TenantAdminColors.mutedText,
          ),
        ],
      ),
    );

    if (item.route == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(item.route!),
        borderRadius: BorderRadius.circular(14),
        child: content,
      ),
    );
  }
}

TenantAdminStatusType _statusType(String? status) {
  switch (status) {
    case 'danger':
      return TenantAdminStatusType.danger;
    case 'warning':
      return TenantAdminStatusType.warning;
    case 'pending':
      return TenantAdminStatusType.pending;
    case 'success':
      return TenantAdminStatusType.success;
    default:
      return TenantAdminStatusType.warning;
  }
}

Color _colorFor(TenantAdminStatusType status) {
  switch (status) {
    case TenantAdminStatusType.danger:
      return TenantAdminColors.danger;
    case TenantAdminStatusType.pending:
      return TenantAdminColors.pending;
    case TenantAdminStatusType.success:
    case TenantAdminStatusType.active:
    case TenantAdminStatusType.online:
      return TenantAdminColors.success;
    case TenantAdminStatusType.warning:
      return TenantAdminColors.warning;
    case TenantAdminStatusType.offline:
    case TenantAdminStatusType.inactive:
      return TenantAdminColors.offline;
  }
}

IconData _iconFor(TenantAdminStatusType status) {
  switch (status) {
    case TenantAdminStatusType.danger:
      return Icons.wifi_off_rounded;
    case TenantAdminStatusType.pending:
      return Icons.group_add_outlined;
    case TenantAdminStatusType.success:
    case TenantAdminStatusType.active:
    case TenantAdminStatusType.online:
      return Icons.check_circle_outline;
    case TenantAdminStatusType.warning:
      return Icons.inventory_2_outlined;
    case TenantAdminStatusType.offline:
    case TenantAdminStatusType.inactive:
      return Icons.cloud_off_outlined;
  }
}
