import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/pos_home_action.dart';
import 'pos_dashboard_card_container.dart';
import 'pos_metric_tile.dart';

class PosOnlineOrdersSummaryCard extends StatelessWidget {
  const PosOnlineOrdersSummaryCard({
    super.key,
    required this.action,
    this.onViewOrders,
  });

  final PosHomeAction action;
  final VoidCallback? onViewOrders;

  @override
  Widget build(BuildContext context) {
    return PosDashboardCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: TenantAdminColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: TenantAdminColors.info,
                  size: 26,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Text(
                  action.label,
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            'Track and fulfill online orders in real time.',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          const Row(
            children: [
              Expanded(
                child: PosMetricTile(
                  value: '12',
                  label: 'Pending',
                  color: TenantAdminColors.warning,
                ),
              ),
              SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: PosMetricTile(
                  value: '8',
                  label: 'Ready',
                  color: TenantAdminColors.success,
                ),
              ),
              SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: PosMetricTile(
                  value: '3',
                  label: 'Delayed',
                  color: TenantAdminColors.danger,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: action.routeExists ? onViewOrders : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(action.buttonLabel),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TenantAdminColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
