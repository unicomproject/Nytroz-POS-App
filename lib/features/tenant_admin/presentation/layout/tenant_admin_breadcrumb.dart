import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

class TenantAdminBreadcrumbItem {
  const TenantAdminBreadcrumbItem({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;
}

class TenantAdminBreadcrumb extends StatelessWidget {
  const TenantAdminBreadcrumb({
    super.key,
    required this.items,
  });

  final List<TenantAdminBreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '>',
                  style: TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            _Crumb(item: items[index], isLast: index == items.length - 1),
          ],
        ],
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.item, required this.isLast});

  final TenantAdminBreadcrumbItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: isLast
          ? TenantAdminColors.bodyText
          : TenantAdminColors.mutedText,
      fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
      fontSize: 13,
    );

    if (item.onTap == null || isLast) {
      return Text(item.label, style: style);
    }

    return InkWell(
      onTap: item.onTap,
      child: Text(item.label, style: style),
    );
  }
}
