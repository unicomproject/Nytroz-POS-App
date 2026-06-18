import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/tenant_dashboard.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_alert_item.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';

class NeedsAttentionCard extends StatelessWidget {
  const NeedsAttentionCard({
    super.key,
    required this.items,
    this.showViewAll = false,
  });

  final List<TenantDashboardAttentionItem> items;
  final bool showViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Needs attention',
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
              ),
              if (showViewAll)
                TextButton(
                  onPressed: () {},
                  child: const Text('View all'),
                ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          for (var index = 0; index < items.length; index++) ...[
            TenantAdminAlertItem(
              title: items[index].title,
              message: items[index].message,
              status: _statusType(items[index].status),
              action: items[index].route == null
                  ? null
                  : TextButton(
                      onPressed: () => context.go(items[index].route!),
                      child: const Text('View'),
                    ),
            ),
            if (index != items.length - 1)
              const SizedBox(height: TenantAdminSpacing.md),
          ],
        ],
      ),
    );
  }
}

TenantAdminStatusType _statusType(String? status) {
  switch (status) {
    case 'danger':
      return TenantAdminStatusType.danger;
    case 'warning':
      return TenantAdminStatusType.warning;
    case 'pending':
      return TenantAdminStatusType.pending;
    case 'success':
      return TenantAdminStatusType.success;
    default:
      return TenantAdminStatusType.warning;
  }
}
