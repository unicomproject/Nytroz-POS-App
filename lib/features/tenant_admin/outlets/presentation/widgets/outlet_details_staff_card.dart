import 'package:flutter/material.dart';

import '../../domain/entities/outlet_details.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import 'outlet_details_section_card.dart';

class OutletDetailsStaffCard extends StatelessWidget {
  const OutletDetailsStaffCard({
    super.key,
    required this.staff,
  });

  final List<OutletRelatedItem> staff;

  @override
  Widget build(BuildContext context) {
    return OutletDetailsSectionCard(
      title: 'Staff at this outlet',
      child: staff.isEmpty
          ? const TenantAdminEmptyState(
              title: 'No staff assigned',
              message: 'Staff assigned to this outlet will appear here.',
            )
          : Column(
              children: [
                for (var index = 0; index < staff.length; index++) ...[
                  _StaffRow(item: staff[index]),
                  if (index != staff.length - 1)
                    const Divider(height: 24, color: TenantAdminColors.border),
                ],
              ],
            ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.item});

  final OutletRelatedItem item;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(item.title);

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: TenantAdminColors.secondary,
          child: Text(
            initials,
            style: const TextStyle(
              color: TenantAdminColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (item.subtitle != null && item.subtitle!.isNotEmpty)
                Text(
                  item.subtitle!,
                  style: TenantAdminTextStyles.muted(context),
                ),
            ],
          ),
        ),
        if (item.status != null && item.status!.isNotEmpty)
          TenantAdminStatusBadge(
            label: item.status!,
            status: TenantAdminStatusType.pending,
          ),
      ],
    );
  }
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '?';
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
