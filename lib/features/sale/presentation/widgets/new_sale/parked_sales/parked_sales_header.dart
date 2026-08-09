import 'package:flutter/material.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ParkedSalesListHeader extends StatelessWidget {
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
  Widget build(BuildContext context) => Padding(
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
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      '$count active',
                      style: TenantAdminTextStyles.muted(context),
                    ),
                  ),
                ],
              ),
            ),
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
