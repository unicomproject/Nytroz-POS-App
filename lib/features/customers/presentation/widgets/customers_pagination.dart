import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_states.dart';

class CustomersPagination extends StatelessWidget {
  const CustomersPagination({
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
    final safeTotalPages = totalPages <= 0 ? 1 : totalPages;
    final pages = _visiblePages(page, safeTotalPages);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(
            'Showing $rangeStart to $rangeEnd of $totalCount customers',
            style: const TextStyle(
              color: Color(0xFF8E9BAE),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _PageIconButton(
            icon: Icons.chevron_left_rounded,
            enabled: !isLoading && page > 1,
            onPressed: () => onPageChanged(page - 1),
          ),
          const SizedBox(width: 4),
          for (final entry in pages)
            entry == null
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child:
                        Text('…', style: TextStyle(color: Color(0xFF8E9BAE))),
                  )
                : _PageNumberButton(
                    page: entry,
                    selected: entry == page,
                    enabled: !isLoading,
                    onPressed: () => onPageChanged(entry),
                  ),
          const SizedBox(width: 4),
          _PageIconButton(
            icon: Icons.chevron_right_rounded,
            enabled: !isLoading && page < safeTotalPages,
            onPressed: () => onPageChanged(page + 1),
          ),
        ],
      ),
    );
  }

  List<int?> _visiblePages(int current, int total) {
    if (total <= 5) {
      return [for (var i = 1; i <= total; i++) i];
    }
    final pages = <int?>{1, total, current};
    for (var i = current - 1; i <= current + 1; i++) {
      if (i > 1 && i < total) {
        pages.add(i);
      }
    }
    final sorted = pages.whereType<int>().toList()..sort();
    final result = <int?>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) {
        result.add(null);
      }
      result.add(sorted[i]);
    }
    return result;
  }
}

class _PageIconButton extends StatelessWidget {
  const _PageIconButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E6ED)),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon,
            size: 18,
            color: enabled ? Colors.black87 : const Color(0xFFC4CBD4)),
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final int page;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? TenantAdminColors.posHomeAccentOrange : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color:
                  selected ? TenantAdminColors.posHomeAccentOrange : const Color(0xFFE2E6ED),
            ),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomersTableBodyStates {
  const CustomersTableBodyStates._();

  static Widget loading() => const Padding(
        padding: EdgeInsets.all(TenantAdminSpacing.xl),
        child: TenantAdminLoadingSkeleton(rowCount: 4),
      );

  static Widget empty({required String title, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: TenantAdminEmptyState(title: title, message: message),
      ),
    );
  }

  static Widget error({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: TenantAdminErrorState(
          title: 'Unable to load customers',
          message: message,
          onRetry: onRetry,
        ),
      ),
    );
  }
}
