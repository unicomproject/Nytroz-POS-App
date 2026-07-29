import 'package:flutter/material.dart';

class ProductsSidebarChildItem extends StatelessWidget {
  const ProductsSidebarChildItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final itemColor = selected ? Colors.white : const Color(0xFFD8E0EE);

    return Padding(
      padding: EdgeInsets.only(
        left: compact ? 8 : 12,
        right: compact ? 4 : 0,
        top: dense ? 2 : 4,
        bottom: dense ? 2 : 4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: dense ? 9 : 10,
            ),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF3F2BFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 28),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: TextStyle(
                      color: itemColor,
                      fontSize: compact ? 12.5 : 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
