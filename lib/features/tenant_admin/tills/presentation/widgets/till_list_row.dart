import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/entities/till.dart';
import '../config/till_row_action_configs.dart';
import 'till_action_menu.dart';
import 'till_operational_status_badge.dart';
import 'till_sales_display.dart';

class TillListRow extends StatelessWidget {
  const TillListRow({
    super.key,
    required this.till,
    required this.visibility,
  });

  final Till till;
  final TillListVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final inlineActions = visibility.visibleRowActions
        .where((action) => action.actionId != TillRowActionId.viewDetails)
        .toList(growable: false);
    final showViewDetails = visibility.visibleRowActions.any(
      (action) => action.actionId == TillRowActionId.viewDetails,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.xl,
        vertical: TenantAdminSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TillIdentity(till: till),
          const SizedBox(width: TenantAdminSpacing.xl),
          SizedBox(
            width: 140,
            child: _OutletColumn(outletName: till.outletName),
          ),
          const SizedBox(width: TenantAdminSpacing.lg),
          SizedBox(
            width: 160,
            child: TillOperationalStatusBadge(
              operationalStatus: till.operationalStatus,
              attentionLabel: till.attentionLabel,
            ),
          ),
          if (visibility.showTodaySales) ...[
            const SizedBox(width: TenantAdminSpacing.lg),
            SizedBox(
              width: 160,
              child: TillSalesDisplay(
                amount: till.todaySalesAmount,
                currency: till.currency,
                lastSyncAt: till.lastSyncAt,
              ),
            ),
          ],
          const Spacer(),
          if (visibility.showActionsColumn)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showViewDetails)
                  TenantAdminSecondaryButton(
                    label: 'View details',
                    icon: Icons.visibility_outlined,
                    onPressed: () =>
                        context.go('/tenant-admin/tills/${till.id}'),
                  ),
                for (final action in inlineActions) ...[
                  if (showViewDetails)
                    const SizedBox(width: TenantAdminSpacing.sm),
                  TenantAdminSecondaryButton(
                    label: action.label,
                    icon: action.icon,
                    onPressed: () => _handleInlineAction(context, action),
                  ),
                ],
                if (visibility.showMoreMenu) ...[
                  if (showViewDetails || inlineActions.isNotEmpty)
                    const SizedBox(width: TenantAdminSpacing.sm),
                  TillActionMenu(
                    till: till,
                    actions: visibility.visibleMoreMenuActions,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  void _handleInlineAction(BuildContext context, TillRowActionConfig action) {
    switch (action.actionId) {
      case TillRowActionId.edit:
        context.go('/tenant-admin/tills/${till.id}/edit');
      case TillRowActionId.viewDetails:
      case TillRowActionId.delete:
      case TillRowActionId.generateActivationCode:
        break;
    }
  }
}

class _TillIdentity extends StatelessWidget {
  const _TillIdentity({required this.till});

  final Till till;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  till.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  till.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.muted(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutletColumn extends StatelessWidget {
  const _OutletColumn({required this.outletName});

  final String outletName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outlet',
          style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          outletName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.bodyText,
          ),
        ),
      ],
    );
  }
}
