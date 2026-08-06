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
      padding: const EdgeInsets.fromLTRB(
        TenantAdminSpacing.lg,
        TenantAdminSpacing.md,
        TenantAdminSpacing.lg,
        TenantAdminSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final summary = Text(
            'Showing $rangeStart to $rangeEnd of $totalCount customers',
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );

          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageIconButton(
                icon: Icons.first_page_rounded,
                enabled: !isLoading && page > 1,
                onPressed: () => onPageChanged(1),
              ),
              _PageIconButton(
                icon: Icons.chevron_left_rounded,
                enabled: !isLoading && page > 1,
                onPressed: () => onPageChanged(page - 1),
              ),
              for (final entry in pages)
                entry == null
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('…'),
                      )
                    : _PageNumberButton(
                        page: entry,
                        selected: entry == page,
                        enabled: !isLoading,
                        onPressed: () => onPageChanged(entry),
                      ),
              _PageIconButton(
                icon: Icons.chevron_right_rounded,
                enabled: !isLoading && page < safeTotalPages,
                onPressed: () => onPageChanged(page + 1),
              ),
              _PageIconButton(
                icon: Icons.last_page_rounded,
                enabled: !isLoading && page < safeTotalPages,
                onPressed: () => onPageChanged(safeTotalPages),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                summary,
                const SizedBox(height: TenantAdminSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: controls,
                ),
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
      ),
    );
  }

  List<int?> _visiblePages(int current, int total) {
    if (total <= 7) {
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
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
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
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          minimumSize: const Size(36, 36),
          backgroundColor:
              selected ? TenantAdminColors.primary : Colors.transparent,
          foregroundColor: selected ? Colors.white : TenantAdminColors.bodyText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          ),
        ),
        child: Text(
          '$page',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// Shared loading/empty/error body for the customers table section.
class CustomersTableBodyStates {
  const CustomersTableBodyStates._();

  static Widget loading() => const SingleChildScrollView(
        padding: EdgeInsets.all(TenantAdminSpacing.xl),
        child: TenantAdminLoadingSkeleton(rowCount: 6),
      );

  static Widget empty({required String title, required String message}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      child: TenantAdminEmptyState(title: title, message: message),
    );
  }

  static Widget error({
    required String message,
    required VoidCallback onRetry,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      child: TenantAdminErrorState(
        title: 'Unable to load customers',
        message: message,
        onRetry: onRetry,
      ),
    );
  }
}
