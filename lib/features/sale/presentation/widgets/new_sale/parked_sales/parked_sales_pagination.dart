import 'package:flutter/material.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ParkedSalesPaginationBar extends StatelessWidget {
  const ParkedSalesPaginationBar({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.loading,
    required this.onPage,
  });

  final int page, pageSize, totalCount;
  final bool loading;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final pages = totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TenantAdminSpacing.lg,
        TenantAdminSpacing.xs,
        TenantAdminSpacing.lg,
        TenantAdminSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Page $page of $pages',
            style: TenantAdminTextStyles.muted(context),
          ),
          IconButton(
            tooltip: 'Previous page',
            onPressed: loading || page <= 1 ? null : () => onPage(page - 1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: loading || page >= pages ? null : () => onPage(page + 1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
