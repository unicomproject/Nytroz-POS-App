import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_mobile_list_card.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../domain/entities/till.dart';
import '../utils/till_api_errors.dart';
import 'till_list_panel.dart';

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
        for (var index = 0; index < tills.length; index++) ...[
          _TillMobileCard(
            till: tills[index],
            visibility: visibility,
          ),
          if (index != tills.length - 1)
            const SizedBox(height: TenantAdminSpacing.md),
        ],
      ],
    );
  }
}

class _TillMobileCard extends StatelessWidget {
  const _TillMobileCard({
    required this.till,
    required this.visibility,
  });

  final Till till;
  final TillListVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      till.code,
      till.outletName,
    ];

    Widget? footer;
    if (visibility.showTodaySales && till.todaySalesAmount != null) {
      footer = Row(
        children: [
          const Expanded(
            child: Text(
              "Today's sales",
              style: TextStyle(color: TenantAdminColors.mutedText),
            ),
          ),
          Text(
            formatTillSales(
              till.todaySalesAmount!,
              till.currency ?? 'GBP',
            ),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (visibility.showViewDetails)
            const Icon(Icons.chevron_right, color: TenantAdminColors.mutedText),
        ],
      );
    }

    return TenantAdminMobileListCard(
      title: till.name,
      subtitle: subtitleParts.join(' • '),
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
      trailing: TenantAdminStatusBadge(
        label: tillOperationalStatusLabel(
          till.operationalStatus,
          attentionLabel: till.attentionLabel,
        ),
        status: tillOperationalStatusType(till.operationalStatus),
      ),
      footer: footer,
      onTap: visibility.showViewDetails
          ? () => context.go('/tenant-admin/tills/${till.id}')
          : null,
    );
  }
}
