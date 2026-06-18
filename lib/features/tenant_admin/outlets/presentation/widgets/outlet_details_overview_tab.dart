import 'package:flutter/material.dart';

import '../../domain/entities/outlet_details.dart';
import '../providers/outlet_details_visibility_provider.dart';
import 'outlet_details_attention_card.dart';
import 'outlet_details_performance_card.dart';
import 'outlet_details_quick_actions.dart';
import 'outlet_details_section_card.dart';
import 'outlet_details_staff_card.dart';
import 'outlet_details_tills_card.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';

class OutletDetailsOverviewTab extends StatelessWidget {
  const OutletDetailsOverviewTab({
    super.key,
    required this.outlet,
    required this.visibility,
  });

  final OutletDetails outlet;
  final OutletDetailsVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= TenantAdminBreakpoints.tablet;

    if (!isWide) {
      return Column(
        children: [
          if (visibility.showPerformance)
            OutletDetailsPerformanceCard(outlet: outlet),
          if (visibility.showPerformance &&
              (visibility.showAssignedTills || visibility.showStaff))
            const SizedBox(height: TenantAdminSpacing.lg),
          if (visibility.showAssignedTills)
            OutletDetailsTillsCard(tills: outlet.assignedTills),
          if (visibility.showAssignedTills && visibility.showStaff)
            const SizedBox(height: TenantAdminSpacing.lg),
          if (visibility.showStaff)
            OutletDetailsStaffCard(staff: outlet.staff),
          if (visibility.showNeedsAttention &&
              (visibility.showAssignedTills || visibility.showStaff))
            const SizedBox(height: TenantAdminSpacing.lg),
          if (visibility.showNeedsAttention)
            OutletDetailsAttentionCard(items: outlet.needsAttention),
          if (visibility.showQuickActions) ...[
            const SizedBox(height: TenantAdminSpacing.lg),
            OutletDetailsSectionCard(
              title: 'Quick actions',
              child: OutletDetailsQuickActions(
                outletId: outlet.id,
                actions: visibility.visibleQuickActions,
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (visibility.showPerformance)
              Expanded(
                flex: 3,
                child: OutletDetailsPerformanceCard(outlet: outlet),
              ),
            if (visibility.showPerformance &&
                (visibility.showAssignedTills || visibility.showStaff))
              const SizedBox(width: TenantAdminSpacing.lg),
            if (visibility.showAssignedTills || visibility.showStaff)
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    if (visibility.showAssignedTills)
                      OutletDetailsTillsCard(tills: outlet.assignedTills),
                    if (visibility.showAssignedTills && visibility.showStaff)
                      const SizedBox(height: TenantAdminSpacing.lg),
                    if (visibility.showStaff)
                      OutletDetailsStaffCard(staff: outlet.staff),
                  ],
                ),
              ),
          ],
        ),
        if (visibility.showNeedsAttention || visibility.showQuickActions) ...[
          const SizedBox(height: TenantAdminSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (visibility.showNeedsAttention)
                Expanded(
                  child: OutletDetailsAttentionCard(
                    items: outlet.needsAttention,
                  ),
                ),
              if (visibility.showNeedsAttention && visibility.showQuickActions)
                const SizedBox(width: TenantAdminSpacing.lg),
              if (visibility.showQuickActions)
                Expanded(
                  child: OutletDetailsSectionCard(
                    title: 'Quick actions',
                    child: OutletDetailsQuickActions(
                      outletId: outlet.id,
                      actions: visibility.visibleQuickActions,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class OutletDetailsPlaceholderTab extends StatelessWidget {
  const OutletDetailsPlaceholderTab({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return OutletDetailsSectionCard(
      title: title,
      child: TenantAdminEmptyState(
        title: title,
        message: message,
      ),
    );
  }
}
