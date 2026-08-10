import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../navigation/inventory_routes.dart';

class InventoryQuickActions extends StatelessWidget {
  const InventoryQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ActionCard(
        title: 'Current Stock',
        subtitle: 'View stock levels across outlets',
        iconData: Icons.inventory_2_outlined,
        color: Colors.blue,
        onTap: () => context.go(InventoryRoutes.currentStock),
      ),
      const _ActionCard(title: 'Opening Stock', subtitle: 'Add opening stock for products', iconData: Icons.unarchive_outlined, color: Colors.purple),
      const _ActionCard(title: 'Stock Adjustment', subtitle: 'Adjust stock for damage, missing or other reasons', iconData: Icons.tune_outlined, color: Colors.orange),
      const _ActionCard(title: 'Stock Count', subtitle: 'Perform physical stock count', iconData: Icons.fact_check_outlined, color: Colors.green),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
                      child: c,
                    ))
                .toList(),
          );
        }

        if (constraints.maxWidth < 1100) {
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.color,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData iconData;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(iconData, color: color, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: const Color(0xFF64748B).withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

