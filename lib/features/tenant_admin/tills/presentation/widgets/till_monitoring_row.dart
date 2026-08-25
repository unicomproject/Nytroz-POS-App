import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/till_monitoring.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../config/till_row_action_configs.dart';
import 'till_delete_dialog.dart';

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

  static const _accent = TenantAdminColors.posHomeAccentOrange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              child: compact ? _buildCompactContent(context, ref) : _buildDesktopContent(context, ref),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopContent(BuildContext context, WidgetRef ref) {
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
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildActionButtons(context, ref).map((btn) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: btn,
              );
            }).toList(),
          ),
        ),
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

  Widget _buildCompactContent(BuildContext context, WidgetRef ref) {
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
            _buildStatusBadge(),
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
        if (_buildActionButtons(context, ref).isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _buildActionButtons(context, ref),
          ),
        ],
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
        'Unassigned',
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

  List<Widget> _buildActionButtons(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);
    final allActions = accessState.maybeWhen(
      data: (access) => [
        ...visibleTillRowActions(access.can, access.canAny),
        ...visibleTillMoreMenuActions(access.can, access.canAny),
      ],
      orElse: () => <TillRowActionConfig>[],
    );

    if (allActions.isEmpty) return [];

    return allActions.map((action) {
      Color color = TenantAdminColors.info;
      if (action.actionId == TillRowActionId.delete) {
        color = TenantAdminColors.danger;
      }

      return _ActionTextBtn(
        icon: action.icon,
        label: action.label,
        color: color,
        onTap: () => _handleAction(context, ref, action),
      );
    }).toList();
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    TillRowActionConfig action,
  ) async {
    switch (action.actionId) {
      case TillRowActionId.delete:
        await TillDeleteDialog.show(
          context: context,
          ref: ref,
          till: item,
        );
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

class _ActionTextBtn extends StatelessWidget {
  const _ActionTextBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
