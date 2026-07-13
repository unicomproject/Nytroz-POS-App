import 'package:flutter/material.dart';

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
    final itemColor = selected ? Colors.white : const Color(0xFFD8E0EE);
    final iconColor = selected
        ? Colors.white
        : const Color(0xFFB8C4D8);

    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 10 : 11,
          ),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3F2BFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF3F2BFF).withValues(alpha: 0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
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
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
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
