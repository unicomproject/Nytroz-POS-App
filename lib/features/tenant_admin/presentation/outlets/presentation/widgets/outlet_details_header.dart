import 'package:flutter/material.dart';

import '../../domain/entities/outlet_details.dart';
import '../../../theme/tenant_admin_theme.dart';
import '../../../widgets/tenant_admin_status_badge.dart';

class OutletDetailsHeader extends StatelessWidget {
  const OutletDetailsHeader({
    super.key,
    required this.outlet,
  });

  final OutletDetails outlet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Wrap(
        spacing: 32,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(child: Icon(Icons.store)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        outlet.name,
                        style: TenantAdminTextStyles.sectionTitle(context),
                      ),
                      const SizedBox(width: 12),
                      TenantAdminStatusBadge(
                        label: outlet.status,
                        status: _statusType(outlet.status),
                      ),
                    ],
                  ),
                  Text(outlet.address, style: TenantAdminTextStyles.muted(context)),
                ],
              ),
            ],
          ),
          _HeaderInfo(
            icon: Icons.person,
            title: 'Manager',
            value: outlet.managerName ?? 'Not assigned',
            subtitle: outlet.managerPhone,
          ),
          _HeaderInfo(
            icon: Icons.access_time,
            title: 'Opening hours',
            value: outlet.openingHours ?? 'Not set',
          ),
          _HeaderInfo(
            icon: Icons.check_circle,
            title: "Today's status",
            value: outlet.todaysStatus ?? 'Unknown',
          ),
        ],
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: TenantAdminColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TenantAdminTextStyles.muted(context)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (subtitle != null) Text(subtitle!),
          ],
        ),
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
      return TenantAdminStatusType.pending;
  }
}
