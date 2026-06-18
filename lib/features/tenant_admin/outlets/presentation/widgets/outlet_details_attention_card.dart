import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/outlet_details.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_alert_item.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import 'outlet_details_section_card.dart';

class OutletDetailsAttentionCard extends StatelessWidget {
  const OutletDetailsAttentionCard({
    super.key,
    required this.items,
  });

  final List<OutletAttentionItem> items;

  @override
  Widget build(BuildContext context) {
    return OutletDetailsSectionCard(
      title: 'Needs attention',
      child: items.isEmpty
          ? const TenantAdminEmptyState(
              title: 'All clear',
              message: 'Nothing needs attention right now.',
            )
          : Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  TenantAdminAlertItem(
                    title: items[index].title,
                    message: items[index].message,
                    status: _statusType(items[index].status),
                    action: items[index].route == null
                        ? null
                        : TextButton(
                            onPressed: () => context.go(items[index].route!),
                            child: const Text('View'),
                          ),
                  ),
                  if (index != items.length - 1)
                    const SizedBox(height: TenantAdminSpacing.md),
                ],
              ],
            ),
    );
  }
}

TenantAdminStatusType _statusType(String? status) {
  switch (status) {
    case 'danger':
      return TenantAdminStatusType.danger;
    case 'warning':
      return TenantAdminStatusType.warning;
    case 'success':
      return TenantAdminStatusType.success;
    default:
      return TenantAdminStatusType.warning;
  }
}
