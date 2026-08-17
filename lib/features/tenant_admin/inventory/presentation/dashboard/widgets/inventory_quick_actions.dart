import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_quick_action_card.dart';
import '../../navigation/inventory_routes.dart';

class InventoryQuickActions extends StatelessWidget {
  const InventoryQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      TenantAdminQuickActionCard(
        title: 'Current Stock',
        subtitle: 'View stock levels across outlets',
        icon: Icons.inventory_2_outlined,
        onTap: () => context.go(InventoryRoutes.currentStock),
      ),
      TenantAdminQuickActionCard(
        title: 'Opening Stock',
        subtitle: 'Manage opening stock entries',
        icon: Icons.add_box_outlined,
        onTap: () => context.go(InventoryRoutes.openingStock),
      ),
      TenantAdminQuickActionCard(
        title: 'Stock Adjustment',
        subtitle: 'Adjust stock manually',
        icon: Icons.swap_vert_outlined,
        onTap: () => context.go(InventoryRoutes.adjustment),
      ),
      TenantAdminQuickActionCard(
        title: 'Stock Count',
        subtitle: 'Perform physical stock count',
        icon: Icons.fact_check_outlined,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Stock Count is not available in this phase (STOCKTAKE_DEFERRED).',
              ),
            ),
          );
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: TenantAdminSpacing.md),
                      child: c,
                    ))
                .toList(),
          );
        }

        if (constraints.maxWidth < 1200) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(child: cards[1]),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(child: cards[2]),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }
}
