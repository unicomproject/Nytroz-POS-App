import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

class TenantAdminPaginationDefaults {
  const TenantAdminPaginationDefaults._();

  static const pageSize = TenantAdminContentTokens.defaultListPageSize;
}

class TenantAdminPaginationBar extends StatelessWidget {
  const TenantAdminPaginationBar({
    super.key,
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
    this.itemLabel = 'records',
  });

  final int currentPage;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int> onPageChanged;
  final String itemLabel;

  int get _safePageSize =>
      pageSize <= 0 ? TenantAdminPaginationDefaults.pageSize : pageSize;

  int get _totalPages {
    if (totalCount <= 0) {
      return 0;
    }

    return math.max(1, (totalCount / _safePageSize).ceil());
  }

  int get _safePage => currentPage.clamp(1, math.max(1, _totalPages));

  int get _rangeStart {
    if (totalCount <= 0) {
      return 0;
    }

    return ((_safePage - 1) * _safePageSize) + 1;
  }

  int get _rangeEnd {
    if (totalCount <= 0) {
      return 0;
    }

    return math.min(_safePage * _safePageSize, totalCount);
  }

  @override
  Widget build(BuildContext context) {
    if (totalCount <= 0) {
      return const SizedBox.shrink();
    }

    final totalPages = _totalPages;
    final page = _safePage;
    final pages = _visiblePages(page, totalPages);

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: TenantAdminColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.lg,
          vertical: TenantAdminSpacing.md,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final rangeText =
                'Showing $_rangeStart–$_rangeEnd of $totalCount $itemLabel';

            final controls = Wrap(
              spacing: TenantAdminSpacing.xs,
              runSpacing: TenantAdminSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _PageNavButton(
                  label: compact ? 'Prev' : 'Previous',
                  icon: Icons.chevron_left_rounded,
                  enabled: page > 1,
                  onPressed: () => onPageChanged(page - 1),
                ),
                for (final pageToken in pages)
                  pageToken == null
                      ? const _PaginationEllipsis()
                      : _PageNumberButton(
                          page: pageToken,
                          active: pageToken == page,
                          onPressed: () => onPageChanged(pageToken),
                        ),
                _PageNavButton(
                  label: 'Next',
                  trailingIcon: Icons.chevron_right_rounded,
                  enabled: page < totalPages,
                  onPressed: () => onPageChanged(page + 1),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rangeText, style: _rangeStyle),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  controls,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: Text(rangeText, style: _rangeStyle)),
                controls,
              ],
            );
          },
        ),
      ),
    );
  }

  static const _rangeStyle = TextStyle(
    color: TenantAdminColors.mutedText,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  List<int?> _visiblePages(int page, int totalPages) {
    if (totalPages <= 7) {
      return [for (var index = 1; index <= totalPages; index++) index];
    }

    if (page <= 4) {
      return [1, 2, 3, 4, 5, null, totalPages];
    }

    if (page >= totalPages - 3) {
      return [
        1,
        null,
        for (var index = totalPages - 4; index <= totalPages; index++) index,
      ];
    }

    return [1, null, page - 1, page, page + 1, null, totalPages];
  }
}

class _PageNavButton extends StatelessWidget {
  const _PageNavButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final IconData? icon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (trailingIcon != null) ...[
            const SizedBox(width: TenantAdminSpacing.xs),
            Icon(trailingIcon, size: 18),
          ],
        ],
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, TenantAdminContentTokens.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.md,
          vertical: TenantAdminSpacing.sm,
        ),
        foregroundColor:
            enabled ? TenantAdminColors.bodyText : TenantAdminColors.offline,
        side: const BorderSide(color: TenantAdminColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.active,
    required this.onPressed,
  });

  final int page;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? TenantAdminColors.primary : TenantAdminColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        side: BorderSide(
          color: active ? TenantAdminColors.primary : TenantAdminColors.border,
        ),
      ),
      child: InkWell(
        onTap: active ? null : onPressed,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: SizedBox(
          width: TenantAdminContentTokens.buttonHeight,
          height: TenantAdminContentTokens.buttonHeight,
          child: Center(
            child: Text(
              '$page',
              style: TextStyle(
                color: active
                    ? TenantAdminColors.surface
                    : TenantAdminColors.bodyText,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaginationEllipsis extends StatelessWidget {
  const _PaginationEllipsis();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: TenantAdminContentTokens.buttonHeight,
      height: TenantAdminContentTokens.buttonHeight,
      child: Center(
        child: Text(
          '…',
          style: TextStyle(
            color: TenantAdminColors.mutedText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
