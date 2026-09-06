import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_sales_permission_visibility.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ParkedSalesListHeader extends ConsumerWidget {
  const ParkedSalesListHeader({
    super.key,
    required this.count,
    required this.refreshing,
    required this.onRefresh,
    required this.onClose,
  });

  final int count;
  final bool refreshing;
  final VoidCallback? onRefresh;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    final showCount =
        PosSalesPermissionVisibility.canShowHeldActiveCount(permissions);
    final canRefresh =
        PosSalesPermissionVisibility.canRefreshHeldList(permissions);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TenantAdminSpacing.lg,
        TenantAdminSpacing.lg,
        TenantAdminSpacing.sm,
        TenantAdminSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parked Sales',
                  style: TenantAdminTextStyles.pageTitle(context),
                ),
                if (showCount) ...[
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      '$count active',
                      style: TenantAdminTextStyles.muted(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canRefresh)
            IconButton(
              tooltip: refreshing
                  ? 'Refreshing parked sales'
                  : 'Refresh parked sales',
              onPressed: onRefresh,
              icon: refreshing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          if (onClose != null)
            IconButton(
              tooltip: 'Close Parked Sales',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}
