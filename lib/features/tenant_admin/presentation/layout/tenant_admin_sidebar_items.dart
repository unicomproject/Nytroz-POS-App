import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

/// Shared white/light sidebar leaf item.
class TenantAdminSidebarItem extends StatelessWidget {
  const TenantAdminSidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    this.enabled = true,
    this.visuallyDisabled = false,
    this.collapsed = false,
    this.compact = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final bool visuallyDisabled;
  final bool collapsed;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = visuallyDisabled || !enabled;
    final itemColor = muted
        ? TenantAdminSidebarTokens.disabledForeground
        : selected
            ? TenantAdminSidebarTokens.activeForeground
            : TenantAdminSidebarTokens.foreground;
    final iconColor = muted
        ? TenantAdminSidebarTokens.disabledForeground
        : selected
            ? TenantAdminSidebarTokens.activeForeground
            : TenantAdminSidebarTokens.icon;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(right: 16),
            padding: EdgeInsets.only(
              left: compact ? 16 : 24,
              right: compact ? 10 : 12,
              top: compact ? 10 : 11,
              bottom: compact ? 10 : 11,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? TenantAdminSidebarTokens.activeBackground
                  : Colors.transparent,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(24),
              ),
            ),
            child: Row(
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
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (muted)
                    const Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: TenantAdminSidebarTokens.disabledForeground,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (collapsed) {
      return Tooltip(
        message: muted ? '$label (unavailable)' : label,
        waitDuration: const Duration(milliseconds: 350),
        child: content,
      );
    }

    return content;
  }
}

/// Expandable sidebar parent — visual alias used by Products menu.
class TenantAdminSidebarExpandableItem extends ProductsSidebarParentAlias {
  const TenantAdminSidebarExpandableItem({
    super.key,
    required super.label,
    required super.icon,
    required super.selected,
    required super.expanded,
    required super.onToggle,
    super.collapsed,
    super.compact,
  });
}

/// Child item alias for catalogue naming.
class TenantAdminSidebarChildItem extends StatelessWidget {
  const TenantAdminSidebarChildItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.compact = false,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return _ChildProxy(
      label: label,
      selected: selected,
      onTap: onTap,
      enabled: enabled,
      compact: compact,
      dense: dense,
    );
  }
}

class TenantAdminSidebarActiveIndicator extends StatelessWidget {
  const TenantAdminSidebarActiveIndicator({super.key, this.active = true});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 4,
      height: 20,
      decoration: BoxDecoration(
        color: active
            ? TenantAdminSidebarTokens.activeForeground
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Local proxies keep products widgets as the expandable implementation without
// introducing a circular import into the products package from this file.
class ProductsSidebarParentAlias extends StatelessWidget {
  const ProductsSidebarParentAlias({
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
          margin: const EdgeInsets.only(right: 16),
          padding: EdgeInsets.only(
            left: compact ? 16 : 24,
            right: compact ? 10 : 12,
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
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: iconColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: content,
    );
  }
}

class _ChildProxy extends StatelessWidget {
  const _ChildProxy({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.enabled,
    required this.compact,
    required this.dense,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final itemColor = !enabled
        ? TenantAdminSidebarTokens.disabledForeground
        : selected
            ? TenantAdminSidebarTokens.activeForeground
            : TenantAdminSidebarTokens.foreground;

    return Padding(
      padding: EdgeInsets.only(
        left: compact
            ? TenantAdminSidebarTokens.compactChildIndent
            : TenantAdminSidebarTokens.childIndent / 2,
        top: dense ? 2 : 4,
        bottom: dense ? 2 : 4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(right: 16),
            padding: EdgeInsets.only(
              left: compact ? 16 : 24,
              right: compact ? 10 : 12,
              top: dense ? 9 : 10,
              bottom: dense ? 9 : 10,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? TenantAdminSidebarTokens.activeBackground
                  : Colors.transparent,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(24),
              ),
            ),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: itemColor,
                fontSize: compact ? 12.5 : 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
