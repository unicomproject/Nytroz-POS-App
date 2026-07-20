import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnSearchPagination extends StatelessWidget {
  const ReturnSearchPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalCount,
    required this.isLoading,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final int rangeStart;
  final int rangeEnd;
  final int totalCount;
  final bool isLoading;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) {
      return const SizedBox.shrink();
    }
    final safeTotalPages = totalPages < 1 ? 1 : totalPages;
    return LayoutBuilder(
      builder: (context, constraints) {
        final summary = Text(
          'Showing $rangeStart–$rangeEnd of $totalCount sales',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
        );
        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Previous page',
              onPressed: !isLoading && page > 1
                  ? () => onPageChanged(page - 1)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              'Page $page of $safeTotalPages',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: !isLoading && page < safeTotalPages
                  ? () => onPageChanged(page + 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        );

        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              summary,
              Align(alignment: Alignment.centerRight, child: controls),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: summary),
            controls,
          ],
        );
      },
    );
  }
}
