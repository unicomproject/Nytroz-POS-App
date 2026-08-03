import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class InventoryPagination extends StatelessWidget {
  const InventoryPagination({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.label,
    required this.onPageChanged,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final String label;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages =
        pageSize <= 0 ? 1 : (totalCount / pageSize).ceil().clamp(1, 9999);
    final rangeStart = totalCount == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final rangeEnd = (page * pageSize).clamp(0, totalCount);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $rangeStart to $rangeEnd of $totalCount $label',
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '$page / $totalPages',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
