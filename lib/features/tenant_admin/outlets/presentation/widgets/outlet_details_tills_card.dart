import 'package:flutter/material.dart';

import '../../domain/entities/outlet_details.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import 'outlet_details_section_card.dart';

class OutletDetailsTillsCard extends StatelessWidget {
  const OutletDetailsTillsCard({
    super.key,
    required this.tills,
  });

  final List<OutletRelatedItem> tills;

  @override
  Widget build(BuildContext context) {
    return OutletDetailsSectionCard(
      title: 'Assigned tills',
      child: tills.isEmpty
          ? const TenantAdminEmptyState(
              title: 'No tills assigned',
              message: 'Assigned tills will appear here when available.',
            )
          : Column(
              children: [
                for (var index = 0; index < tills.length; index++) ...[
                  _TillRow(item: tills[index]),
                  if (index != tills.length - 1)
                    const Divider(height: 24, color: TenantAdminColors.border),
                ],
              ],
            ),
    );
  }
}

class _TillRow extends StatelessWidget {
  const _TillRow({required this.item});

  final OutletRelatedItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: TenantAdminColors.secondary,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: const Icon(
            Icons.point_of_sale,
            color: TenantAdminColors.primary,
            size: 20,
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
            status: _statusType(item.status!),
          ),
        const SizedBox(width: TenantAdminSpacing.sm),
        IconButton(
          onPressed: () {},
          icon:
              const Icon(Icons.more_horiz, color: TenantAdminColors.mutedText),
        ),
      ],
    );
  }
}

TenantAdminStatusType _statusType(String status) {
  switch (status.toLowerCase()) {
    case 'online':
    case 'active':
      return TenantAdminStatusType.active;
    case 'offline':
    case 'inactive':
      return TenantAdminStatusType.inactive;
    default:
      return TenantAdminStatusType.pending;
  }
}
