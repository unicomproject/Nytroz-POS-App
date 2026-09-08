import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

/// Compact icon-and-label action used by Tenant Admin list rows and cards.
class TenantAdminRowAction extends StatelessWidget {
  const TenantAdminRowAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.success = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? TenantAdminColors.danger
        : success
            ? TenantAdminColors.success
            : TenantAdminColors.info;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One item in [TenantAdminOverflowMenu].
class TenantAdminOverflowAction {
  const TenantAdminOverflowAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.onSelected,
    this.destructive = false,
    this.success = false,
    this.enabled = true,
  });

  final String id;
  final IconData icon;
  final String label;
  final VoidCallback onSelected;
  final bool destructive;
  final bool success;
  final bool enabled;
}

/// Three-dot overflow menu that shows a small card of row actions.
class TenantAdminOverflowMenu extends StatelessWidget {
  const TenantAdminOverflowMenu({
    super.key,
    required this.actions,
    this.tooltip = 'Actions',
    this.icon = Icons.more_vert,
    this.iconSize = 22,
    this.iconColor = TenantAdminColors.mutedText,
  });

  final List<TenantAdminOverflowAction> actions;
  final String tooltip;
  final IconData icon;
  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      splashRadius: 20,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      constraints: const BoxConstraints(minWidth: 168),
      menuPadding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        side: const BorderSide(color: TenantAdminColors.border),
      ),
      color: TenantAdminOverlaySurfaces.color,
      surfaceTintColor: TenantAdminOverlaySurfaces.surfaceTint,
      elevation: 8,
      shadowColor: const Color(0x330F172A),
      icon: Icon(icon, size: iconSize, color: iconColor),
      onSelected: (id) {
        for (final action in actions) {
          if (action.id == id && action.enabled) {
            action.onSelected();
            break;
          }
        }
      },
      itemBuilder: (context) => [
        for (final action in actions)
          PopupMenuItem<String>(
            value: action.id,
            enabled: action.enabled,
            child: TenantAdminRowActionMenuItem(
              icon: action.icon,
              label: action.label,
              destructive: action.destructive,
              success: action.success,
            ),
          ),
      ],
    );
  }
}

class TenantAdminRowActionMenuItem extends StatelessWidget {
  const TenantAdminRowActionMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.destructive = false,
    this.success = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? TenantAdminColors.danger
        : success
            ? TenantAdminColors.success
            : TenantAdminColors.info;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: TenantAdminSpacing.md),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
