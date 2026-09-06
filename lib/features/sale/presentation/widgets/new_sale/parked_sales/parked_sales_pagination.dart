import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_sales_permission_visibility.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ParkedSalesPaginationBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    if (!PosSalesPermissionVisibility.canShowHeldPagination(permissions)) {
      return const SizedBox.shrink();
    }

    // Previous / Next / page label share one canonical code: list.pagination.
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
