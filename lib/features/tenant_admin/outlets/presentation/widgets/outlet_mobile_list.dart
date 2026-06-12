import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/outlet.dart';
import '../../../presentation/widgets/tenant_admin_mobile_list_card.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';

class OutletMobileList extends StatelessWidget {
  const OutletMobileList({
    super.key,
    required this.outlets,
  });

  final List<Outlet> outlets;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < outlets.length; index++) ...[
          TenantAdminMobileListCard(
            title: outlets[index].name,
            subtitle:
                '${outlets[index].location}\n${outlets[index].onlineTillCount} Online • ${outlets[index].staffCount} Staff',
            leading: const CircleAvatar(child: Icon(Icons.store)),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TenantAdminStatusBadge(
                  label: outlets[index].status,
                  status: _statusType(outlets[index].status),
                ),
                const SizedBox(height: 8),
                Text(outlets[index].todaysSales),
              ],
            ),
            onTap: () =>
                context.go('/tenant-admin/outlets/${outlets[index].id}'),
          ),
          if (index != outlets.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
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
