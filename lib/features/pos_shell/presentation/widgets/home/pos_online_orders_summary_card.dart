import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/pos_home_action.dart';
import 'pos_dashboard_card_container.dart';

/// Large white "Manage Online Orders" card. The whole card is the button.
///
/// Online orders / e-commerce are excluded in Release 1, so when no supported
/// route exists the card stays in a non-tappable "not available" state.
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
    final canInvoke = action.routeExists && action.isEnabled && onViewOrders != null;

    return Opacity(
      opacity: canInvoke ? 1 : 0.85,
      child: PosDashboardCardContainer(
        onTap: canInvoke ? onViewOrders : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: TenantAdminColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: TenantAdminColors.info,
                    size: 28,
                  ),
                ),
                const Spacer(),
                if (!canInvoke) const _NotAvailablePill(),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            Text(
              action.label,
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              'Track and fulfill online orders in real time.',
              style: TenantAdminTextStyles.muted(context),
            ),
            const Spacer(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                Icons.local_mall_outlined,
                size: 64,
                color: TenantAdminColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotAvailablePill extends StatelessWidget {
  const _NotAvailablePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
      ),
      child: const Text(
        'Coming soon',
        style: TextStyle(
          color: TenantAdminColors.warning,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
