import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class ProductsSidebarChildItem extends StatelessWidget {
  const ProductsSidebarChildItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.visuallyDisabled = false,
    this.compact = false,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  final bool visuallyDisabled;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final muted = visuallyDisabled || !enabled;
    final itemColor = muted
        ? TenantAdminSidebarTokens.disabledForeground
        : selected
            ? TenantAdminSidebarTokens.activeForeground
            : TenantAdminSidebarTokens.foreground;

    return Padding(
      padding: EdgeInsets.only(
        left: compact
            ? TenantAdminSidebarTokens.compactChildIndent
            : TenantAdminSidebarTokens.childIndent / 2,
        right: compact ? 4 : 0,
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
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: dense ? 9 : 10,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? TenantAdminSidebarTokens.activeBackground
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: compact
                      ? TenantAdminSidebarTokens.compactChildIndent
                      : TenantAdminSidebarTokens.childIndent,
                ),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: TextStyle(
                      color: itemColor,
                      fontSize: compact ? 12.5 : 13,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                      height: 1.2,
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
            ),
          ),
        ),
      ),
    );
  }
}
