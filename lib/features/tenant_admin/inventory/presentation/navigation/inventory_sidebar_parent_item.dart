import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class InventorySidebarParentItem extends StatelessWidget {
  const InventorySidebarParentItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.expanded,
    required this.onToggle,
    this.collapsed = false,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool expanded;
  final VoidCallback onToggle;
  final bool collapsed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final active = selected || expanded;
    final itemColor = active
        ? TenantAdminSidebarTokens.activeForeground
        : TenantAdminSidebarTokens.foreground;
    final iconColor = active
        ? TenantAdminSidebarTokens.activeForeground
        : TenantAdminSidebarTokens.icon;

    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin:
              collapsed ? EdgeInsets.zero : const EdgeInsets.only(right: 16),
          padding: EdgeInsets.only(
            left: collapsed ? 0 : (compact ? 16 : 24),
            right: collapsed ? 0 : (compact ? 10 : 12),
            top: compact ? 10 : 11,
            bottom: compact ? 10 : 11,
          ),
          decoration: BoxDecoration(
            color: active
                ? TenantAdminSidebarTokens.activeBackground
                : Colors.transparent,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(24),
            ),
          ),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: iconColor),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: itemColor,
                      fontSize: compact ? 12.5 : 13,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (collapsed) {
      return Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 350),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: content,
    );
  }
}
