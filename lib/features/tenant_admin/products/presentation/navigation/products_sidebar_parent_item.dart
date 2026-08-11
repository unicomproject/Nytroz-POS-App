import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class ProductsSidebarParentItem extends StatelessWidget {
  const ProductsSidebarParentItem({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: active
              ? TenantAdminSidebarTokens.activeBackground
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  try {
                    context.go('/tenant-admin/products');
                  } catch (_) {
                    // Fallback for tests running outside GoRouter context
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                              fontWeight:
                                  active ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (!collapsed)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: content,
    );
  }
}
