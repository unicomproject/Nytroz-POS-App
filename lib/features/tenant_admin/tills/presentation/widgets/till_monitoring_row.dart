import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/theme/tenant_admin_motion.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_management_card.dart';
import '../../domain/entities/till_monitoring.dart';
import '../config/till_row_action_configs.dart';
import 'till_delete_dialog.dart';

/// Outlet-style responsive management card for an individual till.
class TillMonitoringRow extends ConsumerWidget {
  const TillMonitoringRow({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final TillMonitoringItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TenantAdminManagementCard(
      title: item.name,
      badge: _CodeBadge(code: item.code),
      leading: _TillIcon(status: item.displayStatus),
      onTap: onTap,
      metrics: [
        TenantAdminManagementCardMetric(
          label: 'Outlet',
          icon: Icons.storefront_outlined,
          value: Text(
            item.outletName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        TenantAdminManagementCardMetric(
          label: 'Cashier',
          icon: Icons.person_outline,
          value: Text(
            _cashierName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _hasCashier
                  ? TenantAdminColors.bodyText
                  : TenantAdminColors.mutedText,
              fontStyle: _hasCashier ? FontStyle.normal : FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TenantAdminManagementCardMetric(
          label: 'Last activity',
          icon: Icons.schedule_outlined,
          value: Text(
            _formatDate(item.lastActiveAt ?? item.lastDeviceSeenAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      status: TenantAdminAnimatedStatus(
        statusKey: item.displayStatus,
        child: _StatusBadge(status: item.displayStatus),
      ),
      actions: _actions(context, ref),
    );
  }

  bool get _hasCashier {
    final name = item.currentCashierName?.trim();
    return name != null && name.isNotEmpty && name != '-';
  }

  String get _cashierName => _hasCashier ? item.currentCashierName!.trim() : 'Not assigned';

  List<TenantAdminManagementCardAction> _actions(
    BuildContext context,
    WidgetRef ref,
  ) {
    final configs = ref.watch(tenantAdminAccessCheckerProvider).maybeWhen(
          data: (access) => [
            ...visibleTillRowActions(access.can, access.canAny),
            ...visibleTillMoreMenuActions(access.can, access.canAny),
          ],
          orElse: () => const <TillRowActionConfig>[],
        );

    return configs
        .map(
          (action) => TenantAdminManagementCardAction(
            label: action.label,
            icon: action.icon,
            color: action.actionId == TillRowActionId.delete
                ? TenantAdminColors.danger
                : TenantAdminColors.info,
            onPressed: () => _handleAction(context, ref, action),
          ),
        )
        .toList(growable: false);
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    TillRowActionConfig action,
  ) async {
    switch (action.actionId) {
      case TillRowActionId.delete:
        await TillDeleteDialog.show(context: context, ref: ref, till: item);
      case TillRowActionId.generateActivationCode:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activation code generation is not available yet.'),
            ),
          );
        }
      case TillRowActionId.viewDetails:
        context.go('/tenant-admin/tills/${item.id}');
      case TillRowActionId.edit:
        context.go('/tenant-admin/tills/${item.id}/edit');
    }
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return DateFormat('h:mm a').format(date);
    return DateFormat('MMM d, h:mm a').format(date);
  }
}

class _TillIcon extends StatelessWidget {
  const _TillIcon({required this.status});
  final TillDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TillDisplayStatus.online => TenantAdminColors.success,
      TillDisplayStatus.needsAttention => TenantAdminColors.warning,
      TillDisplayStatus.offline || TillDisplayStatus.unknown => TenantAdminColors.danger,
    };
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: Icon(Icons.point_of_sale_rounded, color: color, size: 28),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.sm, vertical: TenantAdminSpacing.xs),
        decoration: BoxDecoration(
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        ),
        child: Text(code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: TenantAdminColors.mutedText)),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TillDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TillDisplayStatus.online => ('Online', TenantAdminColors.success),
      TillDisplayStatus.needsAttention => ('Needs attention', TenantAdminColors.warning),
      TillDisplayStatus.offline || TillDisplayStatus.unknown => ('Offline', TenantAdminColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md, vertical: TenantAdminSpacing.xs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}
