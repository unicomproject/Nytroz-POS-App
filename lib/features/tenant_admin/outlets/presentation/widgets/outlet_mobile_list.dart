import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../domain/entities/outlet.dart';
import '../../../presentation/widgets/tenant_admin_mobile_list_card.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../config/outlet_row_action_configs.dart';

class OutletMobileList extends StatelessWidget {
  const OutletMobileList({
    super.key,
    required this.outlets,
    required this.visibility,
  });

  final List<Outlet> outlets;
  final OutletListVisibility visibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < outlets.length; index++) ...[
          _OutletMobileCard(
            outlet: outlets[index],
            visibility: visibility,
          ),
          if (index != outlets.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OutletMobileCard extends StatelessWidget {
  const _OutletMobileCard({
    required this.outlet,
    required this.visibility,
  });

  final Outlet outlet;
  final OutletListVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];

    if (visibility.showMobileLocation) {
      subtitleParts.add(outlet.location);
    }

    if (visibility.showMobileTillSummary) {
      subtitleParts.add('${outlet.onlineTillCount} Online');
    }

    if (visibility.showMobileStaffSummary) {
      subtitleParts.add('${outlet.staffCount} Staff');
    }

    final subtitle = subtitleParts.isEmpty ? null : subtitleParts.join('\n');

    Widget? trailing;
    if (visibility.showMobileStatusBadge || visibility.showMobileSales) {
      trailing = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (visibility.showMobileStatusBadge)
            TenantAdminStatusBadge(
              label: outlet.status,
              status: _statusType(outlet.status),
            ),
          if (visibility.showMobileStatusBadge && visibility.showMobileSales)
            const SizedBox(height: 8),
          if (visibility.showMobileSales) Text(outlet.todaysSales),
        ],
      );
    }

    return TenantAdminMobileListCard(
      title: outlet.name,
      subtitle: subtitle,
      leading: const CircleAvatar(child: Icon(Icons.store)),
      trailing: trailing,
      footer: visibility.showMobileActionsMenu
          ? Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<OutletRowActionId>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Actions',
                itemBuilder: (context) {
                  return [
                    for (final action in visibility.visibleRowActions)
                      PopupMenuItem<OutletRowActionId>(
                        value: action.actionId,
                        child: ListTile(
                          leading: Icon(action.icon),
                          title: Text(action.label),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                  ];
                },
                onSelected: (actionId) =>
                    _handleAction(context, actionId, outlet),
              ),
            )
          : null,
      onTap: () => context.go('/tenant-admin/outlets/${outlet.id}'),
    );
  }

  void _handleAction(
    BuildContext context,
    OutletRowActionId actionId,
    Outlet outlet,
  ) {
    switch (actionId) {
      case OutletRowActionId.viewDetails:
        context.go('/tenant-admin/outlets/${outlet.id}');
      case OutletRowActionId.edit:
        context.go('/tenant-admin/outlets/${outlet.id}/edit');
      case OutletRowActionId.manageTills:
        context.go('/tenant-admin/tills');
      case OutletRowActionId.manageStaff:
        context.go('/tenant-admin/staff');
      case OutletRowActionId.toggleStatus:
      case OutletRowActionId.delete:
        break;
    }
  }
}

TenantAdminStatusType _statusType(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return TenantAdminStatusType.active;
    case 'inactive':
      return TenantAdminStatusType.inactive;
    default:
      return TenantAdminStatusType.warning;
  }
}
