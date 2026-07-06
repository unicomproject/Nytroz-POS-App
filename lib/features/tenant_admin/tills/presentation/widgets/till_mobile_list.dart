import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_mobile_list_card.dart';
import '../../domain/entities/till.dart';
import '../config/till_row_action_configs.dart';
import 'till_action_menu.dart';
import 'till_operational_status_badge.dart';
import 'till_sales_display.dart';

class TillMobileList extends StatelessWidget {
  const TillMobileList({
    super.key,
    required this.tills,
    required this.visibility,
  });

  final List<Till> tills;
  final TillListVisibility visibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final till in tills) ...[
          TillMobileListItem(
            till: till,
            visibility: visibility,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
        ],
      ],
    );
  }
}

class TillMobileListItem extends StatelessWidget {
  const TillMobileListItem({
    super.key,
    required this.till,
    required this.visibility,
  });

  final Till till;
  final TillListVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final showViewDetails = visibility.visibleRowActions.any(
      (action) => action.actionId == TillRowActionId.viewDetails,
    );
    final showEdit = visibility.visibleRowActions.any(
      (action) => action.actionId == TillRowActionId.edit,
    );

    return TenantAdminMobileListCard(
      title: till.name,
      subtitle: till.code,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: TenantAdminColors.secondary,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: const Icon(
          Icons.point_of_sale_outlined,
          color: TenantAdminColors.primary,
        ),
      ),
      trailing: visibility.showMoreMenu
          ? TillActionMenu(
              till: till,
              actions: visibility.visibleMoreMenuActions,
            )
          : null,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            till.outletName,
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          TillOperationalStatusBadge(
            operationalStatus: till.operationalStatus,
            attentionLabel: till.attentionLabel,
          ),
          if (visibility.showTodaySales) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            TillSalesDisplay(
              amount: till.todaySalesAmount,
              currency: till.currency,
              lastSyncAt: till.lastSyncAt,
            ),
          ],
          if (showViewDetails || showEdit) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            Wrap(
              spacing: TenantAdminSpacing.sm,
              runSpacing: TenantAdminSpacing.sm,
              children: [
                if (showViewDetails)
                  TenantAdminSecondaryButton(
                    label: 'View details',
                    icon: Icons.visibility_outlined,
                    onPressed: () =>
                        context.go('/tenant-admin/tills/${till.id}'),
                  ),
                if (showEdit)
                  TenantAdminSecondaryButton(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    onPressed: () =>
                        context.go('/tenant-admin/tills/${till.id}/edit'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
