import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/outlet_details_quick_action_configs.dart';
import '../../../presentation/widgets/tenant_admin_quick_action_card.dart';

class OutletDetailsQuickActions extends StatelessWidget {
  const OutletDetailsQuickActions({
    super.key,
    required this.outletId,
    required this.actions,
  });

  final String outletId;
  final List<OutletDetailsQuickActionConfig> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        final itemWidth = isWide
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final action in actions)
              SizedBox(
                width: itemWidth,
                child: TenantAdminQuickActionCard(
                  title: action.title,
                  icon: action.icon,
                  onTap: () => context.go(action.routeBuilder(outletId)),
                ),
              ),
          ],
        );
      },
    );
  }
}
